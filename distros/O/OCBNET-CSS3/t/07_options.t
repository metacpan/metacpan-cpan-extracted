# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 8;
BEGIN { use_ok('OCBNET::CSS3') };

my $rv;

use OCBNET::CSS3::Styles::Common;
use OCBNET::CSS3::Styles::References;

# OO interface
my $css = OCBNET::CSS3::Stylesheet->new;

my $code = <<EOF;

.test-01
{
	/* color: red; */
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
	/* color: green; */
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
	/* color: blue; */
	/* css-ref: test-01; */
	margin-top: 70px;
}

.test-07
{
	margin-right: 80px;
}

EOF


$rv = $css->parse($code);

is    ($css->child(0)->option('color'),        'red',       'parse color (shorthand 1)');
is    ($css->child(1)->option('color'),        'red',       'parse color (inherit shorthand 1)');
is    ($css->child(2)->option('color'),        'red',       'parse color (inherit shorthand 1)');
is    ($css->child(3)->option('color'),        'green',     'parse color (set via longhand 4)');
is    ($css->child(4)->option('color'),        'green' ,    'parse color (inherit longhand 1)');
is    ($css->child(5)->option('color'),        'blue',      'parse color (set via longhand 6)');
is    ($css->child(6)->option('color'),        undef,       'parse color (nothing inherited)');
