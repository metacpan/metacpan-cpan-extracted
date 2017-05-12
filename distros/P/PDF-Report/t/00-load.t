#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'PDF::Report' );
}

diag( "Testing PDF::Report $PDF::Report::VERSION, Perl $], $^X" );
