package Queue::Gearman::Job;
use strict;
use warnings;
use utf8;

use Carp qw/carp/;
use Queue::Gearman::Message qw/:headers/;

use Class::Accessor::Lite ro => [qw/
    func
    arg
    handle
    socket
    owner_pid
/], rw => [qw/serialize_method deserialize_method done/];

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        %args,
        owner_pid => $$,
    } => $class;
    return $self;
}

sub is_finished { shift->done }

sub _serialize {
    my ($self, $arg) = @_;
    return scalar $self->serialize_method->($arg);
}

sub _deserialize {
    my ($self, $arg) = @_;
    return scalar $self->deserialize_method->($arg);
}

sub data {
    my ($self, $data) = @_;
    $data = $self->_serialize($data);
    $self->socket->send(HEADER_REQ_WORK_DATA, $self->handle, $data);
}

sub warning {
    my ($self, $msg) = @_;
    $msg = $self->_serialize($msg);
    $self->socket->send(HEADER_REQ_WORK_WARNING, $self->handle, $msg);
}

sub status {
    my ($self, $numerator, $denominator) = @_;
    $self->socket->send(HEADER_REQ_WORK_STATUS, $self->handle, $numerator, $denominator);
}

sub complete {
    my ($self, $res) = @_;
    $res = $self->_serialize(defined $res ? $res : '');
    $self->socket->send(HEADER_REQ_WORK_COMPLETE, $self->handle, $res);
    $self->done(1);
}

sub fail {
    my ($self, $err) = @_;
    if (defined $err) {
        $err = $self->_serialize($err);
        $self->socket->send(HEADER_REQ_WORK_EXCEPTION, $self->handle, $err);
    }
    $self->socket->send(HEADER_REQ_WORK_FAIL, $self->handle);
    $self->done(1);
}

sub DESTROY {
    my $self = shift;
    return if $self->{owner_pid} != $$;
    return if $self->done;
    carp "EXPECT call complete/fail/abort method, but not called.";
}

1;
__END__

=pod

=encoding utf-8

=head1 NAME

Queue::Gearman::Job - TODO

=head1 SYNOPSIS

    use Queue::Gearman::Job;

=head1 DESCRIPTION

TODO

=head1 SEE ALSO

L<perl>

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut
