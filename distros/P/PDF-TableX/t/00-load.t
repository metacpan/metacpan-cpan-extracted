#!perl -T

use Test::More tests => 6;

BEGIN {
	use_ok( 'PDF::TableX::Types' );
	use_ok( 'PDF::TableX::Drawable' );
	use_ok( 'PDF::TableX' );
	use_ok( 'PDF::TableX::Row' );
	use_ok( 'PDF::TableX::Cell' );
	use_ok( 'PDF::TableX::Column' );
}

diag( "Testing PDF::TableX $PDF::TableX::VERSION, Perl $], $^X" );
