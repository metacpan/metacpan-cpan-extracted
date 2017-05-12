#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::LDAP::LDAPhash' );
}

diag( "Testing Net::LDAP::LDAPhash $Net::LDAP::LDAPhash::VERSION, Perl $], $^X" );
