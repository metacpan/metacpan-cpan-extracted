#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'POE::Filter::XML::RPC' );
}

diag( "Testing POE::Filter::XML::RPC $POE::Filter::XML::RPC::VERSION, Perl $], $^X" );
