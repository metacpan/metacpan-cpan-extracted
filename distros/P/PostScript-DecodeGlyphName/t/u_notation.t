use strict; use warnings;

use Test::More;
use PostScript::DecodeGlyphName 'decode_glyph';

my %test = (
	'u0001'   => "\x{01}",
	'u0020'   => "\x{20}",
	'u20AC'   => "\x{20AC}",
	'u1FFFF'  => "\x{1FFFF}",
	'u01FFFF' => "\x{1FFFF}",
	'u10FFFF' => "\x{10FFFF}",
	'uD800'   => '',
	'u0D800'  => '',
	'u00D800' => '',
	'uD87F'   => '',
	'u0D87F'  => '',
	'u00D87F' => '',
	'uDFFF'   => '',
	'u0DFFF'  => '',
	'u00DFFF' => '',
);

plan tests => scalar keys %test;
is decode_glyph( $a ), $b, "Checking '$a'" while ( $a, $b ) = each %test;
