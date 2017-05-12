#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Sub::Information' );
}

diag( "Testing Sub::Information $Sub::Information::VERSION, Perl $], $^X" );
