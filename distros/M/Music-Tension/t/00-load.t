#!perl
use 5.010000;
use strict;
use warnings FATAL => 'all';
use Test::Most;

plan tests => 3;

BEGIN {
  use_ok('Music::Tension')              || print "Bail out!\n";
  use_ok('Music::Tension::Cope')        || print "Bail out!\n";
  use_ok('Music::Tension::PlompLevelt') || print "Bail out!\n";
}

diag("Testing Music::Tension $Music::Tension::VERSION, Perl $], $^X");
