#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Scalar::Andand' );
}

diag( "Testing Scalar::Andand $Scalar::Andand::VERSION, Perl $], $^X" );
