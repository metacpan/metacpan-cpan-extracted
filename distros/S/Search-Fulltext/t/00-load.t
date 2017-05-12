#!perl -T
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Search::Fulltext' ) || print "Bail out!\n";
}

diag( "Testing Search::Fulltext $Search::Fulltext::VERSION, Perl $], $^X" );
