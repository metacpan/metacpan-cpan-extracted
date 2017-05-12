#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok('Search::MultiMatch') || print "Bail out!\n";
}

diag("Testing Search::MultiMatch $Search::MultiMatch::VERSION, Perl $], $^X");
