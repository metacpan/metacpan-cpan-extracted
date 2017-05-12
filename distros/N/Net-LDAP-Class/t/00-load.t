#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::LDAP::Class' );
}

diag( "Testing Net::LDAP::Class $Net::LDAP::Class::VERSION, Perl $], $^X" );
