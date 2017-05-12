#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'POE::Filter::SSL' );
}

diag( "Testing POE::Filter::SSL $POE::Filter::SSL::VERSION, Perl $], $^X" );
