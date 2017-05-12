#!perl -T
use 5.10.0;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok('Music::RecRhythm') || print "Bail out!\n";
}

diag("Testing Music::RecRhythm $Music::RecRhythm::VERSION, Perl $], $^X");
