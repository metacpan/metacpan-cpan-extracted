#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Parse::WebCounter' );
}

diag( "Testing Parse::WebCounter $Parse::WebCounter::VERSION, Perl $], $^X" );
