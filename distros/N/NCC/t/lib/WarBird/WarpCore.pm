package WarBird::WarpCore;

use Moose;
use Import::Into;

has calls => (
  is => 'ro',
  default => sub {[]},
);

sub energize {
  my ( $self, $target ) = @_;
  Moose->import::into($_[1]);
  push @{$self->calls}, '+'.$target;
}

sub enervate {
  my ( $self, $target ) = @_;
  push @{$self->calls}, '-'.$target;
}

1;