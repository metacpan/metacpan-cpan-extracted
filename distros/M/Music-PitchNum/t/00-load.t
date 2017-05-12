#!perl
use 5.010000;
use strict;
use warnings FATAL => 'all';
use Test::Most;

plan tests => 3;

BEGIN {
  use_ok('Music::PitchNum')         || print "Bail out!\n";
  use_ok('Music::PitchNum::ABC')    || print "Bail out!\n";
  use_ok('Music::PitchNum::German') || print "Bail out!\n";
}

diag("Testing Music::PitchNum $Music::PitchNum::VERSION, Perl $], $^X");
