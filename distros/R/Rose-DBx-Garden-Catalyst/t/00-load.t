#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Rose::DBx::Garden::Catalyst' );
}

diag( "Testing Rose::DBx::Garden::Catalyst $Rose::DBx::Garden::Catalyst::VERSION, Perl $], $^X" );
