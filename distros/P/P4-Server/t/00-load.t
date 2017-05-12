#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'P4::Server' );
}

diag( "Testing P4::Server $P4::Server::VERSION, Perl $], $^X" );
