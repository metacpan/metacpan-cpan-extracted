#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::LDAP::posixGroup' );
}

diag( "Testing Net::LDAP::posixGroup $Net::LDAP::posixGroup::VERSION, Perl $], $^X" );
