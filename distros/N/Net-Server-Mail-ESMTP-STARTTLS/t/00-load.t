#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::Server::Mail::ESMTP::STARTTLS' );
}

diag( "Testing Net::Server::Mail::ESMTP::STARTTLS $Net::Server::Mail::ESMTP::STARTTLS::VERSION, Perl $], $^X" );
