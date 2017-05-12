
use strict;
use warnings;

package Test::SubPipeline::Class;
use Sub::Pipeline -class => order => [ qw(first second third) ];

sub first {
  my ($self, $arg) = @_;

  $arg->{first} = 1;
}

sub second {
  my ($self, $arg) = @_;

  die unless $arg->{first};
  $arg->{second} = 2;
}

sub third {
  my ($self, $arg) = @_;

  die unless $arg->{first} and $arg->{second};
  $arg->{third} = 3;

  Sub::Pipeline::Success->throw(value => "OK!!");
}

1;
