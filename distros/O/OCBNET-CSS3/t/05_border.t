# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 37;
BEGIN { use_ok('OCBNET::CSS3') };

my $rv;

use OCBNET::CSS3::Styles::Border;
use OCBNET::CSS3::Styles::References;

# OO interface
my $css = OCBNET::CSS3::Stylesheet->new;

my $code = <<EOF;

.test-01
{
	/* css-id: test-01; */
	border: 1px solid;
}

.test-02
{
	/* css-id: test-02; */
	/* css-ref: test-01; */
	border-style: dotted;
}

.test-03
{
	/* css-id: test-03; */
	/* css-ref: test-02; */
	border: 5px;
}

EOF


$rv = $css->parse($code);

is    ($css->child(0)->style('border-top-width'),      '1px',         'parse border-top-width (shorthand)');
is    ($css->child(0)->style('border-left-width'),     '1px',         'parse border-left-width (shorthand)');
is    ($css->child(0)->style('border-bottom-width'),   '1px',         'parse border-bottom-width (shorthand)');
is    ($css->child(0)->style('border-right-width'),    '1px',         'parse border-right-width (shorthand)');
is    ($css->child(0)->style('border-top-style'),      'solid',       'parse border-top-style (shorthand)');
is    ($css->child(0)->style('border-left-style'),     'solid',       'parse border-left-style (shorthand)');
is    ($css->child(0)->style('border-bottom-style'),   'solid',       'parse border-bottom-style (shorthand)');
is    ($css->child(0)->style('border-right-style'),    'solid',       'parse border-right-style (shorthand)');
is    ($css->child(0)->style('border-top-color'),      'transparent', 'parse border-top-width (shorthand default)');
is    ($css->child(0)->style('border-left-color'),     'transparent', 'parse border-left-width (shorthand default)');
is    ($css->child(0)->style('border-bottom-color'),   'transparent', 'parse border-bottom-width (shorthand default)');
is    ($css->child(0)->style('border-right-color'),    'transparent', 'parse border-right-width (shorthand default)');

is    ($css->child(1)->style('border-top-width'),      '1px',         'parse border-top-width (inherit from shorthand 1)');
is    ($css->child(1)->style('border-left-width'),     '1px',         'parse border-left-width (inherit from shorthand 1)');
is    ($css->child(1)->style('border-bottom-width'),   '1px',         'parse border-bottom-width (inherit from shorthand 1)');
is    ($css->child(1)->style('border-right-width'),    '1px',         'parse border-right-width (inherit from shorthand 1)');
is    ($css->child(1)->style('border-top-style'),      'dotted',      'parse border-top-style (longhand)');
is    ($css->child(1)->style('border-left-style'),     'dotted',      'parse border-left-style (longhand)');
is    ($css->child(1)->style('border-bottom-style'),   'dotted',      'parse border-bottom-style (longhand)');
is    ($css->child(1)->style('border-right-style'),    'dotted',      'parse border-right-style (longhand)');
is    ($css->child(1)->style('border-top-color'),      'transparent', 'parse border-top-width (inherit from shorthand 1)');
is    ($css->child(1)->style('border-left-color'),     'transparent', 'parse border-left-width (inherit from shorthand 1)');
is    ($css->child(1)->style('border-bottom-color'),   'transparent', 'parse border-bottom-width (inherit from shorthand 1)');
is    ($css->child(1)->style('border-right-color'),    'transparent', 'parse border-right-width (inherit from shorthand 1)');

is    ($css->child(2)->style('border-top-width'),      '5px',         'parse border-top-width (shorthand)');
is    ($css->child(2)->style('border-left-width'),     '5px',         'parse border-left-width (shorthand)');
is    ($css->child(2)->style('border-bottom-width'),   '5px',         'parse border-bottom-width (shorthand)');
is    ($css->child(2)->style('border-right-width'),    '5px',         'parse border-right-width (shorthand)');
is    ($css->child(2)->style('border-top-style'),      'none',        'parse border-top-style (shorthand default)');
is    ($css->child(2)->style('border-left-style'),     'none',        'parse border-left-style (shorthand default)');
is    ($css->child(2)->style('border-bottom-style'),   'none',        'parse border-bottom-style (shorthand default)');
is    ($css->child(2)->style('border-right-style'),    'none',        'parse border-right-style (shorthand default)');
is    ($css->child(2)->style('border-top-color'),      'transparent', 'parse border-top-width (shorthand default)');
is    ($css->child(2)->style('border-left-color'),     'transparent', 'parse border-left-width (shorthand default)');
is    ($css->child(2)->style('border-bottom-color'),   'transparent', 'parse border-bottom-width (shorthand default)');
is    ($css->child(2)->style('border-right-color'),    'transparent', 'parse border-right-width (shorthand default)');
