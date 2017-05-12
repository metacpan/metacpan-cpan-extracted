#!perl
use strict;
use warnings;
use Test::Most;

plan tests => 1;

BEGIN {
  use_ok('Music::AtonalUtil')         || print "Bail out!\n";
}

diag("Testing Music::AtonalUtil $Music::AtonalUtil::VERSION, Perl $], $^X");
