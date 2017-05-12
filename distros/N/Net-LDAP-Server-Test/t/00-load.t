#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::LDAP::Server::Test' );
}

diag( "Testing Net::LDAP::Server::Test $Net::LDAP::Server::Test::VERSION, Perl $], $^X" );
