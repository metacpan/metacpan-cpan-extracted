package Pipe::Tube::Grep;
use strict;
use warnings;
use 5.006;

use base 'Pipe::Tube';

our $VERSION = '0.05';

sub init {
    my ($self, $expr) = @_;
    $self->logger("Receiving the grep expression: $expr");
    $self->{expr} = $expr;
    return $self;
}

sub run {
    my ($self, @input) = @_;

    $self->logger("The grep expression: $self->{expr}");
    if ("Regexp" eq ref $self->{expr}) {
        return grep /$self->{expr}/, @input;
    } else {
        my $sub = $self->{expr};
        return grep { $sub->($_) } @input;
    }
}

1;

