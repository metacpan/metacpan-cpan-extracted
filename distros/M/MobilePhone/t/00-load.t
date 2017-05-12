#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'MobilePhone' );
}

diag( "Testing MobilePhone $MobilePhone::VERSION, Perl $], $^X" );
