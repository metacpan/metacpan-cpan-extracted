#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Scalar::MoreUtils' );
}

diag( "Testing Scalar::MoreUtils $Scalar::MoreUtils::VERSION, Perl $], $^X" );
