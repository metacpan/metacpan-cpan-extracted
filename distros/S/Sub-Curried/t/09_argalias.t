#!/usr/bin/perl
use strict; use warnings;

use Test::More tests=>3;

use Sub::Curried;

curry set ($x, $y, $z) {
  foreach my $arg (@_) {
    $arg = 1;
  }
}

my ($a, $b, $c) = (0, 0, 0);
set($a)->($b)->($c);

is $a, 1, 'Simple test to verify argument aliasing';
is $b, 1, 'Simple test to verify argument aliasing';
is $c, 1, 'Simple test to verify argument aliasing';
