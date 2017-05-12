# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 29;
BEGIN { use_ok('OCBNET::CSS3') };

my $rv;

use OCBNET::CSS3::Styles::Padding;
use OCBNET::CSS3::Styles::References;

# OO interface
my $css = OCBNET::CSS3::Stylesheet->new;

my $code = <<EOF;

.test-01
{
	/* css-id: test-01; */
	padding: 11px;
}

.test-02
{
	/* css-id: test-02; */
	/* css-ref: test-01; */
	padding: 12px 22px;
}

.test-03
{
	/* css-id: test-03; */
	/* css-ref: test-01; */
	padding: 13px 23px 33px;
}

.test-04
{
	/* css-id: test-04; */
	/* css-ref: test-01; */
	padding: 14px 24px 34px 44px;
}

.test-05
{
	/* css-id: test-03; */
	/* css-ref: test-04; */
	padding-left: 50px;
	padding-bottom: 60px;
}

.test-06
{
	/* css-ref: test-01; */
	padding-top: 70px;
}

.test-07
{
	padding-right: 80px;
}

EOF


$rv = $css->parse($code);

is    ($css->child(0)->style('padding-top'),    '11px',      'parse padding-top (shorthand 1)');
is    ($css->child(0)->style('padding-right'),  '11px',      'parse padding-right (shorthand 1)');
is    ($css->child(0)->style('padding-bottom'), '11px',      'parse padding-bottom (shorthand 1)');
is    ($css->child(0)->style('padding-left'),   '11px',      'parse padding-left (shorthand 1)');

is    ($css->child(1)->style('padding-top'),    '12px',      'parse padding-top (shorthand 2)');
is    ($css->child(1)->style('padding-right'),  '22px',      'parse padding-right (shorthand 2)');
is    ($css->child(1)->style('padding-bottom'), '12px',      'parse padding-bottom (shorthand 2)');
is    ($css->child(1)->style('padding-left'),   '22px',      'parse padding-left (shorthand 2)');

is    ($css->child(2)->style('padding-top'),    '13px',      'parse padding-top (shorthand 3)');
is    ($css->child(2)->style('padding-right'),  '23px',      'parse padding-right (shorthand 3)');
is    ($css->child(2)->style('padding-bottom'), '33px',      'parse padding-bottom (shorthand 3)');
is    ($css->child(2)->style('padding-left'),   '23px',      'parse padding-left (shorthand 3)');

is    ($css->child(3)->style('padding-top'),    '14px',      'parse padding-top (shorthand 4)');
is    ($css->child(3)->style('padding-right'),  '24px',      'parse padding-right (shorthand 4)');
is    ($css->child(3)->style('padding-bottom'), '34px',      'parse padding-bottom (shorthand 4)');
is    ($css->child(3)->style('padding-left'),   '44px',      'parse padding-left (shorthand 4)');

is    ($css->child(4)->style('padding-top'),    '14px',      'parse padding-top (inherit shorthand 4)');
is    ($css->child(4)->style('padding-right'),  '24px',      'parse padding-right (inherit shorthand 4)');
is    ($css->child(4)->style('padding-bottom'), '60px',      'parse padding-bottom (set via longhand)');
is    ($css->child(4)->style('padding-left'),   '50px',      'parse padding-left (set via longhand)');

is    ($css->child(5)->style('padding-top'),    '70px',      'parse padding-top (set via longhand)');
is    ($css->child(5)->style('padding-right'),  '11px',      'parse padding-right (inherit shorthand 1)');
is    ($css->child(5)->style('padding-bottom'), '11px',      'parse padding-bottom (inherit shorthand 1)');
is    ($css->child(5)->style('padding-left'),   '11px',      'parse padding-left (inherit shorthand 1)');

is    ($css->child(6)->style('padding-top'),    undef,       'parse padding-top (nothing inherited)');
is    ($css->child(6)->style('padding-right'),  '80px',      'parse padding-right (set via longhand)');
is    ($css->child(6)->style('padding-bottom'), undef,       'parse padding-bottom (nothing inherited)');
is    ($css->child(6)->style('padding-left'),   undef,       'parse padding-left (nothing inherited)');
