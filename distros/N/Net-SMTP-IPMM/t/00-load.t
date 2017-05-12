#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::SMTP::IPMM' );
}

diag( "Testing Net::SMTP::IPMM $Net::SMTP::IPMM::VERSION, Perl $], $^X" );
