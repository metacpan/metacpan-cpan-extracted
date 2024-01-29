#!perl -T

use Test::More tests => 3;

BEGIN {
	use_ok( 'SVGPDF::CSS' );
	use_ok( 'SVGPDF::PAST' );
	use_ok( 'SVGPDF::Contrib::Bogen' );
}

