#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Rose::DBx::Garden' );
}

diag( "Testing Rose::DBx::Garden $Rose::DBx::Garden::VERSION, Perl $], $^X" );
