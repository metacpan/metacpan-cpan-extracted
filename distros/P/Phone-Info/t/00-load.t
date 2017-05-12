#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Phone::Info' );
}

diag( "Testing Phone::Info $Phone::Info::VERSION, Perl $], $^X" );
