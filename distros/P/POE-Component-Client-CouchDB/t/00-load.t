#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'POE::Component::Client::CouchDB' );
}

diag( "Testing POE::Component::Client::CouchDB $POE::Component::Client::CouchDB::VERSION, Perl $], $^X" );
