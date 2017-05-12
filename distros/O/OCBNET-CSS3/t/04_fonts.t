# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 25;
BEGIN { use_ok('OCBNET::CSS3') };

my $rv;

use OCBNET::CSS3::Styles::Font;
use OCBNET::CSS3::Styles::References;

# OO interface
my $css = OCBNET::CSS3::Stylesheet->new;

my $code = <<EOF;

.test-01
{
	/* css-id: test-01; */
	font: italic bold 12px/30px Georgia, serif;;
}

.test-02
{
	/* css-id: test-02; */
	/* css-ref: test-01; */
	font-family: tahoma;
}

.test-03
{
	/* css-id: test-03; */
	/* css-ref: test-01; */
	line-height: 40px;
}

.test-04
{
	/* css-id: test-04; */
	/* css-ref: test-03; */
	font-size: 10px;
}

EOF

$rv = $css->parse($code);

is    ($css->child(0)->style('font-style'),      'italic',           'parse font-style (shorthand 1)');
is    ($css->child(0)->style('font-variant'),    'normal',           'parse font-variant (shorthand 1)');
is    ($css->child(0)->style('font-weight'),     'bold',             'parse font-weight (shorthand 1)');
is    ($css->child(0)->style('font-size'),       '12px',             'parse font-size (shorthand 1)');
is    ($css->child(0)->style('line-height'),     '30px',             'parse line-height (shorthand 1)');
is    ($css->child(0)->style('font-family'),     'Georgia, serif',   'parse font-family (shorthand 1)');

is    ($css->child(1)->style('font-style'),      'italic',           'parse font-style (inherit shorthand 1)');
is    ($css->child(1)->style('font-variant'),    'normal',           'parse font-variant (inherit shorthand 1)');
is    ($css->child(1)->style('font-weight'),     'bold',             'parse font-weight (inherit shorthand 1)');
is    ($css->child(1)->style('font-size'),       '12px',             'parse font-size (inherit shorthand 1)');
is    ($css->child(1)->style('line-height'),     '30px',             'parse line-height (inherit shorthand 1)');
is    ($css->child(1)->style('font-family'),     'tahoma',           'parse font-family (longhand 2)');

is    ($css->child(2)->style('font-style'),      'italic',           'parse font-style (inherit shorthand 1)');
is    ($css->child(2)->style('font-variant'),    'normal',           'parse font-variant (inherit shorthand 1)');
is    ($css->child(2)->style('font-weight'),     'bold',             'parse font-weight (inherit shorthand 1)');
is    ($css->child(2)->style('font-size'),       '12px',             'parse font-size (inherit shorthand 1)');
is    ($css->child(2)->style('line-height'),     '40px',             'parse line-height (longhand 3)');
is    ($css->child(2)->style('font-family'),     'Georgia, serif',   'parse font-family (inherit shorthand 1)');

is    ($css->child(3)->style('font-style'),      'italic',           'parse font-style (shorthand 1)');
is    ($css->child(3)->style('font-variant'),    'normal',           'parse font-variant (shorthand 1)');
is    ($css->child(3)->style('font-weight'),     'bold',             'parse font-weight (shorthand 1)');
is    ($css->child(3)->style('font-size'),       '10px',             'parse font-size (longhand 4)');
is    ($css->child(3)->style('line-height'),     '40px',             'parse line-height (inherit longhand 3))');
is    ($css->child(3)->style('font-family'),     'Georgia, serif',   'parse font-family (shorthand 1)');