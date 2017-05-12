#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'PSPP' );
}

diag( "Testing PSPP $PSPP::VERSION, Perl $], $^X" );
