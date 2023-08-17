package Pipe::Tube::For;
use strict;
use warnings;
use 5.006;

use base 'Pipe::Tube';

our $VERSION = '0.06';

sub init {
    my ($self, @values) = @_;
    $self->logger("Receiving values for for loop: " .  join "|", @values);
    $self->{data} = \@values;
    return $self;
}

sub run {
    my ($self) = @_;
    $self->logger("Current values in for loop: " .  join "|", @{ $self->{data} });
    return @{ $self->{data}} ?  shift @{ $self->{data} } : ();
}

1;

