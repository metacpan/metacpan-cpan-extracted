use strict; use warnings;

use Test::More;
use PostScript::DecodeGlyphName 'decode_glyph';

my %test = (
	'uni0001'     => "\x{01}",
	'uni0020'     => "\x{20}",
	'uni00200020002000200020' => "\x{20}"x5,
	'uni20AC'     => "\x{20AC}",
	'uni20AC20AC' => "\x{20AC}"x2,
	'uni1FFFF'    => '',
	'uni01FFFF'   => '',
	'uni10FFFF'   => '',
	'uniD800'     => '',
	'uni0D800'    => '',
	'uni00D800'   => '',
	'uniD87F'     => '',
	'uni0D87F'    => '',
	'uni00D87F'   => '',
	'uniDFFF'     => '',
	'uni0DFFF'    => '',
	'uni00DFFF'   => '',
);

plan tests => scalar keys %test;
is decode_glyph( $a ), $b, "Checking '$a'" while ( $a, $b ) = each %test;
