#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Search::ByPrefix' ) || print "Bail out!\n";
}

diag( "Testing Search::ByPrefix $Search::ByPrefix::VERSION, Perl $], $^X" );
