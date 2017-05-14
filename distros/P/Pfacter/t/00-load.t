#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Pfacter' );
}

diag( "Testing Pfacter $Pfacter::VERSION, Perl $], $^X" );

