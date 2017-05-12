#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Normalize' );
}

diag( "Testing Normalize $Normalize::VERSION, Perl $], $^X" );
