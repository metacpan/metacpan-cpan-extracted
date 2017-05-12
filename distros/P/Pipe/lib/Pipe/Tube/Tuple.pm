package Pipe::Tube::Tuple;
use strict;
use warnings;
use 5.006;

use base 'Pipe::Tube';

our $VERSION = '0.05';

sub init {
    my ($self, @arrays) = @_;
    $self->{sources} = \@arrays;
    $self->{current_index} = 0;

    my $l = 0;
    $l = ($l > @$_ ? $l : @$_) for @arrays;
    $self->{longest_array} = $l;

    $self->logger("The tuple received " . @arrays . " sources");
    return $self;
}

sub run {
    my ($self) = @_;

    return if $self->{current_index} >= $self->{longest_array};

    my @tuple;
    foreach my $source (@{ $self->{sources} }) {
      push @tuple, $source->[ $self->{current_index} ];
    }
    $self->{current_index}++;
    return \@tuple;
}


1;

