#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Purple' );
}

diag( "Testing Purple $Purple::VERSION, Perl $], $^X" );
