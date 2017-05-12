#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::TCP::PtyServer' );
}

diag( "Testing Net::TCP::PtyServer $Net::TCP::PtyServer::VERSION, Perl $], $^X" );
