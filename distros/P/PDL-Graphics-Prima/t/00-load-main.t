#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'PDL::Graphics::Prima' )
		or BAIL_OUT('Unable to load PDL::Graphics::Prima!');
}

diag( "Testing PDL::Graphics::Prima $PDL::Graphics::Prima::VERSION, Perl $], $^X" );