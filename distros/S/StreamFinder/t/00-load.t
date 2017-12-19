#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'StreamFinder' ) || print "Bail out!\n";
}

diag( "Testing StreamFinder $StreamFinder::VERSION, Perl $], $^X" );
