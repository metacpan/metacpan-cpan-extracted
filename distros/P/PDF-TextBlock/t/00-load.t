#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'PDF::TextBlock' );
}

diag( "Testing PDF::TextBlock $PDF::TextBlock::VERSION, Perl $], $^X" );
