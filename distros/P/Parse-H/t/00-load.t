#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Parse::H' );
}

diag( "Testing Parse::H $Parse::H::VERSION, Perl $], $^X" );
