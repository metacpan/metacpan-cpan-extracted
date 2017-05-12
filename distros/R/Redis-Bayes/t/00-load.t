#!perl -T
use 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Redis::Bayes' ) || print "Bail out!\n";
}

diag( "Testing Redis::Bayes $Redis::Bayes::VERSION, Perl $], $^X" );
