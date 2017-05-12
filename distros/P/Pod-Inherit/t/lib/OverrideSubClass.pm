package OverrideSubClass;
use warnings;
use strict;
use base 'SimpleBaseClass';

sub mymethod {
  # This sub exists both here and in SimpleBaseClass.
}

1;
