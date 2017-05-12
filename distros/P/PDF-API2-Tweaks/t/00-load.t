#! perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'PDF::API2::Tweaks' );
}

diag( "Testing PDF::API2::Tweaks $PDF::API2::Tweaks::VERSION, Perl $], $^X" );
