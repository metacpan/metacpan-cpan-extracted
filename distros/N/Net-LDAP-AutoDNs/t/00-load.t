#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::LDAP::AutoDNs' );
}

diag( "Testing Net::LDAP::AutoDNs $Net::LDAP::AutoDNs::VERSION, Perl $], $^X" );
