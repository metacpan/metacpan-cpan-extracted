#!perl -T

use Test::More tests => 3;

BEGIN {
	use_ok( 'Net::CIDR::Lookup' );
	use_ok( 'Net::CIDR::Lookup::Tie' );
	use_ok( 'Net::CIDR::Lookup::IPv6' );
}

diag( "Testing Net::CIDR::Lookup $Net::CIDR::Lookup::VERSION, Perl $], $^X" );
diag( "Testing Net::CIDR::Lookup::Tie $Net::CIDR::Lookup::Tie::VERSION, Perl $], $^X" );
