#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'POE::Component::Client::eris' );
}

diag( "Testing POE::Component::Client::eris $POE::Component::Client::eris::VERSION, Perl $], $^X" );
