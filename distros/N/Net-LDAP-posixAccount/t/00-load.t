#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::LDAP::posixAccount' );
}

diag( "Testing Net::LDAP::posixAccount $Net::LDAP::posixAccount::VERSION, Perl $], $^X" );
