#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'PDL::Graphics::Prima::Simple' )
		or BAIL_OUT('Unable to load PDL::Graphics::Prima::Simple!');
}

diag( "Testing PDL::Graphics::Prima::Simple, Perl $], $^X" );