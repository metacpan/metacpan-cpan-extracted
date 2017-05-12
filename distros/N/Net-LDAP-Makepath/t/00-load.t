#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::LDAP::Makepath' );
}

diag( "Testing Net::LDAP::Makepath $Net::LDAP::Makepath::VERSION, Perl $], $^X" );
