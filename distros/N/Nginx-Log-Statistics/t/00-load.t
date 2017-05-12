#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Nginx::Log::Statistics' ) || print "Bail out!\n";
}

diag( "Testing Nginx::Log::Statistics $Nginx::Log::Statistics::VERSION, Perl $], $^X" );
