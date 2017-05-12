#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::LDAP::AutoServer' );
}

diag( "Testing Net::LDAP::AutoServer $Net::LDAP::AutoServer::VERSION, Perl $], $^X" );
