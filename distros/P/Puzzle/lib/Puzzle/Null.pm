package Puzzle::Null;

use 5.008;
use strict;
use warnings;

BEGIN {
  $Puzzle::Null::VERSION = '0.18';
}
# ABSTRACT: Implements the Null Class design pattern
use overload
  'bool'   => sub { 0 },
  '""'     => sub { '' },
  '0+'     => sub { 0 },
  fallback => 1;
our $null = bless {}, __PACKAGE__;
sub AUTOLOAD { $null }
1;
