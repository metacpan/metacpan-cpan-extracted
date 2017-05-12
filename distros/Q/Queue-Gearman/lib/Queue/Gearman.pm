package Queue::Gearman;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.01";

use Queue::Gearman::Pool;
use Queue::Gearman::Message qw/:headers :msgtypes/;
use Queue::Gearman::Task;
use Queue::Gearman::Taskset;
use Queue::Gearman::Job;
use Queue::Gearman::Util qw/dumper/;
use Scalar::Util qw/weaken/;
use List::Util qw/shuffle/;
use Digest::MD5 qw/md5_hex/;
use Time::HiRes;

use constant DEFAULT_TIMEOUT            => 1;
use constant DEFAULT_DEQUEUE_TIMEOUT    => 1;
use constant DEFAULT_WAIT_TIMEOUT       => 1;
use constant DEFAULT_INACTIVITY_TIMEOUT => 10;

use Class::Accessor::Lite ro => [qw/
    servers
    prefix
    timeout
    dequeue_timeout
    wait_timeout
    inactivity_timeout
    serialize_method
    deserialize_method
/];

my %ENQUEUE_HEADER = (
    background => +{
        priority => +{
            high   => HEADER_REQ_SUBMIT_JOB_HIGH_BG,
            normal => HEADER_REQ_SUBMIT_JOB_BG,
            low    => HEADER_REQ_SUBMIT_JOB_LOW_BG,
        },
    },
    foreground => +{
        priority => +{
            high   => HEADER_REQ_SUBMIT_JOB_HIGH,
            normal => HEADER_REQ_SUBMIT_JOB,
            low    => HEADER_REQ_SUBMIT_JOB_LOW,
        },
    },
);

sub _noop     {}
sub _identity { $_[0] }

sub new {
    my $class = shift;
    my $self  = bless +{
        timeout            => DEFAULT_TIMEOUT,
        dequeue_timeout    => DEFAULT_DEQUEUE_TIMEOUT,
        wait_timeout       => DEFAULT_WAIT_TIMEOUT,
        inactivity_timeout => DEFAULT_INACTIVITY_TIMEOUT,
        serialize_method   => \&_identity,
        deserialize_method => \&_identity,
        ability_map        => {},
        @_
    } => $class;
    return $self;
}

sub taskset {
    my $self = shift;
    return $self->{taskset} ||= Queue::Gearman::Taskset->new(
        wait_timeout       => $self->wait_timeout,
        serialize_method   => $self->serialize_method,
        deserialize_method => $self->deserialize_method,
    );
}

sub client_id {
    my $self = shift;
    return $self->{client_id} ||= md5_hex(rand() . $$ . {} . time);
}

sub _pool {
    my ($self, $role) = @_;
    return $self->{pool}->{$role} if exists $self->{pool}->{$role};
    $self->{pool}->{$role} = Queue::Gearman::Pool->new(
        servers            => $self->servers,
        timeout            => $self->timeout,
        inactivity_timeout => $self->inactivity_timeout,
        on_connect_do      => $self->_on_connect_do($role),
    );
    return $self->{pool}->{$role};
}

sub _on_connect_do {
    my ($self, $role) = @_;
    if ($role eq 'worker') {
        weaken($self);
        return sub {
            my $socket = shift;
            $socket->send(HEADER_REQ_PRE_SLEEP);
            $socket->send(HEADER_REQ_SET_CLIENT_ID, $self->client_id);

            for my $args (values %{ $self->{ability_map} }) {
                my @msg = $self->_make_can_do_msg(@$args);
                $socket->send(@msg);
            }
        };
    }
    return \&_noop;
}

sub _encode_func {
    my ($self, $func) = @_;
    my $prefix = $self->prefix or return $func;
    return "$prefix\t$func";
}

sub _decode_func {
    my ($self, $func) = @_;
    my $prefix = $self->prefix or return $func;
    $func =~ s/^\Q$prefix\t//;
    return $func;
}

sub _serialize {
    my ($self, $arg) = @_;
    return scalar $self->serialize_method->($arg);
}

sub _deserialize {
    my ($self, $arg) = @_;
    return scalar $self->deserialize_method->($arg);
}

sub can_do {
    my $self = shift;
    my ($func) = @_;

    my @msg = $self->_make_can_do_msg(@_);
    $_->send(@msg) for $self->_pool('worker')->all;

    $self->{ability_map}->{$func} = [@_];
}

sub cant_do {
    my ($self, $func) = @_;

    delete $self->{ability_map}->{$func};

    my @msg = $self->_make_cant_do_msg($func);
    $_->send(@msg) for $self->_pool('worker')->all;
}

sub _make_can_do_msg {
    my $self = shift;
    my $func = shift;
    return @_ == 1 ? (HEADER_REQ_CAN_DO_TIMEOUT,  $self->_encode_func($func), @_)
                   : (HEADER_REQ_CAN_DO,          $self->_encode_func($func));
}

sub _make_cant_do_msg {
    my ($self, $func) = @_;
    return (HEADER_REQ_CANT_DO, $self->_encode_func($func));
}

sub reset_abilities {
    my $self = shift;
    for my $socket ($self->_pool('worker')->all) {
        $socket->send(HEADER_REQ_RESET_ABILITIES);
    }
    %{$self->{ability_map}} = ();
}

sub enqueue { shift->enqueue_background(@_) }

sub enqueue_background {
    my $self = shift;
    my $opt  = exists $_[3] ? $_[3] : +{};

    my $unique   = $opt->{unique}   || '';
    my $priority = $opt->{priority} || 'normal';
    my $header   = exists $ENQUEUE_HEADER{background}{$priority} ? $ENQUEUE_HEADER{background}{$priority}
                                                                 : HEADER_REQ_SUBMIT_JOB_BG;
    return $self->_enqueue($header, 1, $unique, @_);
}

sub enqueue_forground {
    my $self = shift;
    my $opt  = exists $_[3] ? $_[3] : +{};

    my $unique   = $opt->{unique}   || '';
    my $priority = $opt->{priority} || 'normal';
    my $header   = exists $ENQUEUE_HEADER{foreground}{$priority} ? $ENQUEUE_HEADER{foreground}{$priority}
                                                                 : HEADER_REQ_SUBMIT_JOB;
    return $self->_enqueue($header, 0, $unique, @_);
}

sub _enqueue {
    my ($self, $header, $is_background, $unique, $func, $arg) = @_;

    my $socket = $self->_pool('client')->pick();
    my $res = $socket->send($header, $self->_encode_func($func), $unique, $self->_serialize($arg))
           && $socket->recv();
    return unless defined $res;

    if ($res->{msgtype} eq MSGTYPE_RES_JOB_CREATED) {
        my ($handle) = @{ $res->{args} };
        return Queue::Gearman::Task->new(
            func          => $func,
            handle        => $handle,
            arg           => $arg,
            taskset       => $self->taskset,
            socket        => $socket,
            is_background => $is_background,
        );
    }

    die "Unexpected res: ", dumper($res);
}

sub dequeue {
    my ($self, $timeout) = @_;
    $timeout ||= $self->dequeue_timeout();

    my $timeout_at = Time::HiRes::time + $timeout;

    while (Time::HiRes::time < $timeout_at) {
        for my $socket (shuffle $self->_pool('worker')->all) {
            $socket->send(HEADER_REQ_GRAB_JOB);

        TRY_RECV:
            my $res = $socket->recv();
            next unless defined $res;

            if ($res->{msgtype} eq MSGTYPE_RES_JOB_ASSIGN) {
                my ($handle, $func, $arg) = @{ $res->{args} };
                return Queue::Gearman::Job->new(
                    func               => $self->_decode_func($func),
                    handle             => $handle,
                    arg                => $self->_deserialize($arg),
                    socket             => $socket,
                    serialize_method   => $self->serialize_method,
                    deserialize_method => $self->deserialize_method,
                );
            }
            elsif ($res->{msgtype} eq MSGTYPE_RES_NO_JOB) {
                $socket->send(HEADER_REQ_PRE_SLEEP);
                next;
            }
            elsif ($res->{msgtype} eq MSGTYPE_RES_NOOP) {
                goto TRY_RECV; ## retry to recv
            }

            die "Unexpected res: ", dumper($res);
        }
    }

    return;
}

1;
__END__

=encoding utf-8

=head1 NAME

Queue::Gearman - Queue like low-level interface for Gearman.

=head1 SYNOPSIS

    use Queue::Gearman;
    use JSON;

    sub add {
        my $args = shift;
        return $args->{left} + $args->{rigth};
    }

    my $queue = Queue::Gearman->new(
        servers            => ['127.0.0.1:6667'],
        serialize_method   => \&JSON::encode_json,
        deserialize_method => \&JSON::decode_json,
    );
    $queue->can_do('add');

    my $task = $queue->enqueue_forground(add => { left => 1, rigth => 2 })
        or die 'failure';
    $queue->enqueue_background(add => { left => 2, rigth => 1 })
        or die 'failure';

    my $job = $queue->dequeue();
    if ($job && $job->func eq 'add') {
        my $res = eval { add($job->arg) };
        if (my $e = $@) {
            $job->fail($e);
        }
        else {
            $job->complete($res);
        }
    }

    $task->wait();
    print $task->result, "\n"; ## => 3

=head1 DESCRIPTION

Queue::Gearman is ...

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut

