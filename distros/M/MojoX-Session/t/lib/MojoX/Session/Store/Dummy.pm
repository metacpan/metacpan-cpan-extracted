package MojoX::Session::Store::Dummy;

use strict;
use warnings;

use base 'MojoX::Session::Store';

__PACKAGE__->attr('sessions' => sub {{}});

sub create {
    my ($self, $sid, $expires, $data) = @_;

    $self->sessions->{$sid} = {expires => $expires, data => $data};
}

sub load {
    my ($self, $sid) = @_;

    return ($self->sessions->{$sid}->{expires}, $self->sessions->{$sid}->{data});
}

sub update {
    my ($self, $sid, $expires, $data) = @_;

    $self->sessions->{$sid} = {expires => $expires, data => $data};
}

sub delete {
    my ($self, $sid) = @_;

    delete $self->sessions->{$sid};
}

1;
