#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'Pod::Advent' );
}

diag( "Testing Pod::Advent $Pod::Advent::VERSION, Perl $], $^X" );
