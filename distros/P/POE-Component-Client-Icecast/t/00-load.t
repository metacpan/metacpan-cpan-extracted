#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'POE::Component::Client::Icecast' );
}

diag( "Testing POE::Component::Client::Icecast $POE::Component::Client::Icecast::VERSION, Perl $], $^X" );
