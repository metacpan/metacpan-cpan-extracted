#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'POE::Filter::SimpleHTTP' );
}

diag( "Testing POE::Filter::SimpleHTTP $POE::Filter::SimpleHTTP::VERSION, Perl $], $^X" );
