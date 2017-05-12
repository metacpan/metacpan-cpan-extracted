#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'TRD::Uranai' );
}

diag( "Testing TRD::Uranai $TRD::Uranai::VERSION, Perl $], $^X" );
