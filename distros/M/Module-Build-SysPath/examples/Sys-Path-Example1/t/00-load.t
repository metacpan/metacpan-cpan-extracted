#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Sys::Path::Example1' );
}

diag( "Testing Sys::Path::Example1 $Sys::Path::Example1::VERSION, Perl $], $^X" );
