#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'PDL::IO::Touchstone' ) || print "Bail out!\n";
}

diag( "Testing PDL::IO::Touchstone $PDL::IO::Touchstone::VERSION, Perl $], $^X" );
