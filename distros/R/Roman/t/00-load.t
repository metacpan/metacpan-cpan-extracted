#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Roman' );
}

diag( "Testing Roman $Roman::VERSION, Perl $], $^X" );
