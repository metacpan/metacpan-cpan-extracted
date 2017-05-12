#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'POE::Component::SASLAuthd' );
}

diag( "Testing POE::Component::SASLAuthd $POE::Component::SASLAuthd::VERSION, Perl $], $^X" );
