package Acme;
use warnings;
use strict;

sub new {
  # This is a constructor
  my $class = shift;

  my $self = {};
  bless $self, $class;
  return $self;
}

sub no_comments {
  my $self = shift;
  return 42;
}


