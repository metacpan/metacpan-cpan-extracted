#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'OpenVZ::BC' );
}

diag( "Testing OpenVZ::BC $OpenVZ::BC::VERSION, Perl $], $^X" );
