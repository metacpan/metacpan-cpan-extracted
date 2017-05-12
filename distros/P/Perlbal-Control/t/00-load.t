#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Perlbal::Control' );
}

diag( "Testing Perlbal::Control $Perlbal::Control::VERSION, Perl $], $^X" );
