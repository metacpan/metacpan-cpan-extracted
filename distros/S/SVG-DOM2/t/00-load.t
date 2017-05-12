#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'SVG::DOM2' );
}

diag( "Testing SVG::DOM2 $SVG::DOM2::VERSION, Perl $], $^X" );
