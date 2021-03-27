#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok('Search::Typesense') || print "Bail out!\n";
}

diag("Testing Search::Typesense $Search::Typesense::VERSION, Perl $], $^X");
