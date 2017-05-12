#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Rose::DBx::AutoReconnect' );
}

diag( "Testing Rose::DBx::AutoReconnect $Rose::DBx::AutoReconnect::VERSION, Perl $], $^X" );
