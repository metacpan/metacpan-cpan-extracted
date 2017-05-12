#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Readonly::BeginLift' );
}

diag( "Testing Readonly::BeginLift $Readonly::BeginLift::VERSION, Perl $], $^X" );
