#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Scalar::Lazy' );
}

diag( "Testing Scalar::Lazy $Scalar::Lazy::VERSION, Perl $], $^X" );
