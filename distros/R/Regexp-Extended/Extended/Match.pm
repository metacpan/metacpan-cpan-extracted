package Regexp::Extended::Match;

use strict;
use Carp;

sub new {
  my ($this, $name, $value, $pos) = @_;
  my $class = ref($this) || $this;
  my $self = {
    'name'   => $name,
    'value'  => $value,
    'end'    => $pos,
    'start'  => undef,
    'length' => undef,
    'childs' => undef,
    'parent' => undef,
    'dirty'  => 0,
  };
  bless $self, $class;
  return $self;
}

return 1;
