package OrePAN2::Role::HasLogger;

use strict;
use warnings;

use OrePAN2::Logger;

use Role::Tiny;

our $VERSION = '2.0.0';

sub log { ## no critic
  my ($self) = @_;

  return $self->{log}
    if $self->{log};

  $self->{log} = OrePAN2::Logger->new;

  return $self->{log};
}

1;
