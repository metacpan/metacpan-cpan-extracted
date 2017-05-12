#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::Squid::Auth::Engine' );
}

diag( "Testing Net::Squid::Auth::Engine $Net::Squid::Auth::Engine::VERSION, Perl $], $^X" );
