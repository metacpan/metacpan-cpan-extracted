#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::LDAP::Batch' );
}

diag( "Testing Net::LDAP::Batch $Net::LDAP::Batch::VERSION, Perl $], $^X" );
