#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'PDF::Kit' );
}

diag( "Testing PDF::Kit $PDF::Kit::VERSION, Perl $], $^X" );
