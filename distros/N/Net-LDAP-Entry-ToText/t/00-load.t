#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::LDAP::Entry::ToText' );
}

diag( "Testing Net::LDAP::Entry::ToText $Net::LDAP::Entry::ToText::VERSION, Perl $], $^X" );
