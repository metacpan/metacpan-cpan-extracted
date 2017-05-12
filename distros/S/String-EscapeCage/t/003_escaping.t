#!perl -T

use warnings;
use strict;
use Test::More tests => 7;

BEGIN {
	use_ok( 'String::EscapeCage', qw( cage uncage escapehtml ) );
}

my $plain = cage 'plain text';
isa_ok( $plain, 'String::EscapeCage' );

is( uncage $plain, 'plain text',
  'Uncaging works' );

is( $plain->escapehtml, 'plain text',
  'Escaping a plain text string gives a string' );

is( escapehtml "still $plain", 'still plain text',
  'Interpolatation of a plain text EscapeCage gives plain text' );

my $withchars = cage 'some <b>bold</b> stuff';
isa_ok( $withchars, 'String::EscapeCage' );

is( $withchars->escapehtml, 'some &lt;b&gt;bold&lt;/b&gt; stuff',
  'Escaping simple characters gives proper HTML entities' );
