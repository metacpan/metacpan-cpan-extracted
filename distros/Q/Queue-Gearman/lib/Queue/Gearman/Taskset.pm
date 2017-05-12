package Queue::Gearman::Taskset;
use strict;
use warnings;
use utf8;

use Queue::Gearman::Select;
use Queue::Gearman::Message qw/:headers :msgtypes/;
use Queue::Gearman::Util qw/dumper/;
use Scalar::Util qw/weaken/;

use Class::Accessor::Lite new => 1, rw => [qw/
    wait_timeout
    serialize_method
    deserialize_method
/];

sub _serialize {
    my ($self, $arg) = @_;
    return scalar $self->serialize_method->($arg);
}

sub _deserialize {
    my ($self, $arg) = @_;
    return scalar $self->deserialize_method->($arg);
}

sub all {
    my $self = shift;
    return values %{ $self->{task} };
}

sub add {
    my ($self, $task) = @_;
    $self->select->add($task->socket);
    $self->{task}->{$task->handle} = $task;
    weaken($self->{task}->{$task->handle});
}

sub get {
    my ($self, $handle) = @_;
    return unless exists $self->{task}->{$handle};
    return $self->{task}->{$handle};
}

sub remove {
    my ($self, $handle) = @_;
    return unless exists $self->{task}->{$handle};

    my $task = delete $self->{task}->{$handle}
        or return;

    my %fileno = map { $_->socket->sock->fileno => 1 } $self->all;
    unless (exists $fileno{$task->socket->sock->fileno}) {
        $self->select->remove($task->socket);
    }
    return $task;
}

sub select :method {
    my $self = shift;
    return $self->{select} ||= Queue::Gearman::Select->new(map { $_->socket } $self->all);
}

sub update {
    my ($self, $timeout) = shift;
    $timeout ||= $self->wait_timeout;

    for my $socket ($self->select->can_read($timeout)) {
        my $res = $socket->recv();
        next unless defined $res;

        if ($res->{msgtype} eq MSGTYPE_RES_WORK_FAIL) {
            my ($handle) = @{ $res->{args} };
            my $task = $self->get($handle);
            $task->fail(1);
            $task->done(1);
        }
        elsif ($res->{msgtype} eq MSGTYPE_RES_WORK_EXCEPTION) {
            my ($handle, $err) = @{ $res->{args} };
            $err = $self->_deserialize($err);

            my $task = $self->get($handle);
            $task->exception($err);
        }
        elsif ($res->{msgtype} eq MSGTYPE_RES_WORK_WARNING) {
            my ($handle, $msg) = @{ $res->{args} };
            $msg = $self->_deserialize($msg);

            my $task = $self->get($handle);
            $task->warning($msg);
        }
        elsif ($res->{msgtype} eq MSGTYPE_RES_WORK_DATA) {
            my ($handle, $data) = @{ $res->{args} };
            $data = $self->_deserialize($data);

            my $task = $self->get($handle);
            $task->data($data);
        }
        elsif ($res->{msgtype} eq MSGTYPE_RES_WORK_COMPLETE) {
            my ($handle, $result) = @{ $res->{args} };
            $result = $self->_deserialize($result);

            my $task = $self->get($handle);
            $task->result($result);
            $task->done(1);
        }
        else {
            die "Unexpected res: ", dumper($res);
        }
    }
}

sub update_statuses {
    my $self = shift;

    for my $task ($self->all) {
        next unless $task->is_background;

        my $res = $task->socket->send(HEADER_REQ_GET_STATUS, $task->handle) && $task->socket->recv();
        if ($res->{msgtype} eq MSGTYPE_RES_STATUS_RES) {
            my ($handle, $numerator, $denominator) = @{ $res->{args} };
            my $task = $self->get($handle);
            $task->status([$numerator, $denominator]);
        }
        else {
            die "Unexpected res: ", dumper($res);
        }
    }
}

sub wait :method {
    my $self = shift;
    $self->update(@_);
    return grep { $_->is_finished } $self->all;
}

1;
__END__
