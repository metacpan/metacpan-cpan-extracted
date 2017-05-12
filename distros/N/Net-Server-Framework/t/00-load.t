#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::Server::Framework' );
}

diag( "Testing Net::Server::Framework $Net::Server::Framework::VERSION, Perl $], $^X" );
