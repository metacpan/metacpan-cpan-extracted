use strict;
use warnings;

package InsideOut::BaseArray;

use constant FOO => 0;

sub new {
  my $class = shift;
  my %p = @_;
  my $self = bless [] => $class;
  $self->[FOO] = $p{base_foo};
  return $self;
}

sub base_foo {
  my $self = shift;
  if (@_) { $self->[FOO] = shift }
  return $self->[FOO];
}

1;
