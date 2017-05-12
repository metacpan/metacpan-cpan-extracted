#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Sub::Private' );
}

diag( "Testing Sub::Private $Sub::Private::VERSION, Perl $], $^X" );
