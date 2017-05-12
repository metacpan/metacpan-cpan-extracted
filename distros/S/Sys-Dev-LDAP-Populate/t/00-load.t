#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Sys::Dev::LDAP::Populate' );
}

diag( "Testing Sys::Dev::LDAP::Populate $Sys::Dev::LDAP::Populate::VERSION, Perl $], $^X" );
