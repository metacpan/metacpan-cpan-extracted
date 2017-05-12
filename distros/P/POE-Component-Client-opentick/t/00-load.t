#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'POE::Component::Client::opentick' );
}

diag( "Testing POE::Component::Client::opentick $POE::Component::Client::opentick::VERSION, Perl $], $^X" );
