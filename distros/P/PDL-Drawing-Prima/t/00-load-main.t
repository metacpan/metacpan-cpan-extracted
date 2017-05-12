#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'PDL::Drawing::Prima' )
		or BAIL_OUT('Unable to load PDL::Drawing::Prima!');
}

diag( "Testing PDL::Drawing::Prima $PDL::Drawing::Prima::VERSION, Perl $], $^X" );