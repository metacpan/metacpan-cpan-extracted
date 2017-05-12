package OverloadBaseClass;
use warnings;
use strict;
use overload 
  "+" => sub {$$_[0] + $$_[1]},
  fallback => 'daylight savings time';

1;
