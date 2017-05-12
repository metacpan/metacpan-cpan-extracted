#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Omega::DP41::Data::Current' );
}

diag( "Testing Omega::DP41::Data::Current $Omega::DP41::Data::Current::VERSION, Perl $], $^X" );
