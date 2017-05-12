#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'MySQL::Insert' );
}

diag( "Testing MySQL::Insert $MySQL::Insert::VERSION, Perl $], $^X" );
