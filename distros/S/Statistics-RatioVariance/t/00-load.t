#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Statistics::RatioVariance' ) || print "Bail out!\n";
}

diag( "Testing Statistics::RatioVariance $Statistics::RatioVariance::VERSION, Perl $], $^X" );
