# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 29;
BEGIN { use_ok('OCBNET::CSS3') };

my $rv;

use OCBNET::CSS3::Styles::Margin;
use OCBNET::CSS3::Styles::References;

# OO interface
my $css = OCBNET::CSS3::Stylesheet->new;

my $code = <<EOF;

.test-01
{
	/* css-id: test-01; */
	margin: 11px;
}

.test-02
{
	/* css-id: test-02; */
	/* css-ref: test-01; */
	margin: 12px 22px;
}

.test-03
{
	/* css-id: test-03; */
	/* css-ref: test-01; */
	margin: 13px 23px 33px;
}

.test-04
{
	/* css-id: test-04; */
	/* css-ref: test-01; */
	margin: 14px 24px 34px 44px;
}

.test-05
{
	/* css-id: test-03; */
	/* css-ref: test-04; */
	margin-left: 50px;
	margin-bottom: 60px;
}

.test-06
{
	/* css-ref: test-01; */
	margin-top: 70px;
}

.test-07
{
	margin-right: 80px;
}

EOF


$rv = $css->parse($code);

is    ($css->child(0)->style('margin-top'),    '11px',      'parse margin-top (shorthand 1)');
is    ($css->child(0)->style('margin-right'),  '11px',      'parse margin-right (shorthand 1)');
is    ($css->child(0)->style('margin-bottom'), '11px',      'parse margin-bottom (shorthand 1)');
is    ($css->child(0)->style('margin-left'),   '11px',      'parse margin-left (shorthand 1)');

is    ($css->child(1)->style('margin-top'),    '12px',      'parse margin-top (shorthand 2)');
is    ($css->child(1)->style('margin-right'),  '22px',      'parse margin-right (shorthand 2)');
is    ($css->child(1)->style('margin-bottom'), '12px',      'parse margin-bottom (shorthand 2)');
is    ($css->child(1)->style('margin-left'),   '22px',      'parse margin-left (shorthand 2)');

is    ($css->child(2)->style('margin-top'),    '13px',      'parse margin-top (shorthand 3)');
is    ($css->child(2)->style('margin-right'),  '23px',      'parse margin-right (shorthand 3)');
is    ($css->child(2)->style('margin-bottom'), '33px',      'parse margin-bottom (shorthand 3)');
is    ($css->child(2)->style('margin-left'),   '23px',      'parse margin-left (shorthand 3)');

is    ($css->child(3)->style('margin-top'),    '14px',      'parse margin-top (shorthand 4)');
is    ($css->child(3)->style('margin-right'),  '24px',      'parse margin-right (shorthand 4)');
is    ($css->child(3)->style('margin-bottom'), '34px',      'parse margin-bottom (shorthand 4)');
is    ($css->child(3)->style('margin-left'),   '44px',      'parse margin-left (shorthand 4)');

is    ($css->child(4)->style('margin-top'),    '14px',      'parse margin-top (inherit shorthand 4)');
is    ($css->child(4)->style('margin-right'),  '24px',      'parse margin-right (inherit shorthand 4)');
is    ($css->child(4)->style('margin-bottom'), '60px',      'parse margin-bottom (set via longhand)');
is    ($css->child(4)->style('margin-left'),   '50px',      'parse margin-left (set via longhand)');

is    ($css->child(5)->style('margin-top'),    '70px',      'parse margin-top (set via longhand)');
is    ($css->child(5)->style('margin-right'),  '11px',      'parse margin-right (inherit shorthand 1)');
is    ($css->child(5)->style('margin-bottom'), '11px',      'parse margin-bottom (inherit shorthand 1)');
is    ($css->child(5)->style('margin-left'),   '11px',      'parse margin-left (inherit shorthand 1)');

is    ($css->child(6)->style('margin-top'),    undef,       'parse margin-top (nothing inherited)');
is    ($css->child(6)->style('margin-right'),  '80px',      'parse margin-right (set via longhand)');
is    ($css->child(6)->style('margin-bottom'), undef,       'parse margin-bottom (nothing inherited)');
is    ($css->child(6)->style('margin-left'),   undef,       'parse margin-left (nothing inherited)');
