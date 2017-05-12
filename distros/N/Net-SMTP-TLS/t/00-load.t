#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::SMTP::TLS' );
}

diag( "Testing Net::SMTP::TLS $Net::SMTP::TLS::VERSION, Perl $], $^X" );
