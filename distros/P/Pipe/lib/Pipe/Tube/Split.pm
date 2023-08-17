package Pipe::Tube::Split;
use strict;
use warnings;
use 5.006;

use base 'Pipe::Tube';

our $VERSION = '0.06';

sub init {
    my ($self, $expr) = @_;
    $self->logger("Receiving the split expression: $expr");
    if ("Regexp" eq ref $expr) {
      $self->{expr} = $expr;
    } elsif (not ref $expr) {
      $self->{expr} = qr/\Q$expr/;
    } else {
      die "Unrecognized type of parameter for split\n";
    }
    return $self;
}

sub run {
    my ($self, @input) = @_;

    $self->logger("The grep expression: $self->{expr}");
    return map { [ split /$self->{expr}/, $_ ] } @input;
}

1;

