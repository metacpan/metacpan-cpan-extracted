#!perl 
use 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Tapper::API' ) || print "Bail out!\n";
}

diag( "Testing Tapper::API $Tapper::API::VERSION, Perl $], $^X" );
