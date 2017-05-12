#!perl -T

use Test::More tests => 4;

BEGIN {
	use_ok( 'Net::Squid::Purge' );
	use_ok( 'Net::Squid::Purge::Multicast' );
	use_ok( 'Net::Squid::Purge::HTTP' );
	use_ok( 'Net::Squid::Purge::UDP' );
}

diag( "Testing Net::Squid::Purge $Net::Squid::Purge::VERSION, Perl $], $^X" );
