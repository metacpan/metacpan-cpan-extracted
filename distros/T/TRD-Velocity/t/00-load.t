#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'TRD::Velocity' );
}

diag( "Testing TRD::Velocity $TRD::Velocity::VERSION, Perl $], $^X" );
