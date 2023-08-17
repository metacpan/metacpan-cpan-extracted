package Pipe::Tube::Map;
use strict;
use warnings;
use 5.006;

use base 'Pipe::Tube';

our $VERSION = '0.06';

sub init {
    my ($self, $expr) = @_;
    $self->logger("Receiving the map expression: $expr");
    $self->{expr} = $expr;
    return $self;
}

sub run {
    my ($self, @input) = @_;

    $self->logger("The map expression: $self->{expr}");
    if ("Regexp" eq ref $self->{expr}) {
        return map /$self->{expr}/, @input;
    } else {
        my $sub = $self->{expr};
        return map { $sub->($_) } @input;
    }
}

1;

