#!perl 
use 5.012;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'PDL::Dims' ) || print "Bail out!\n";
}

diag( "Testing PDL::Dims $PDL::Dims::VERSION, Perl $], $^X" );
