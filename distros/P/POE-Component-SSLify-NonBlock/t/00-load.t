#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'POE::Component::SSLify::NonBlock' );
}

diag( "Testing POE::Component::SSLify::NonBlock $POE::Component::SSLify::NonBlock::VERSION, Perl $], $^X" );
