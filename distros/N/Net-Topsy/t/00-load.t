#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::Topsy' );
}

diag( "Testing Net::Topsy $Net::Topsy::VERSION, Perl $], $^X" );
