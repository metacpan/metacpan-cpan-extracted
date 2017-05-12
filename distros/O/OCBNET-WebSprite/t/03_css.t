# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 9;
BEGIN { use_ok('OCBNET::CSS3') };

my $rv;

use OCBNET::CSS3::Styles::References;
use OCBNET::CSS3::Styles::WebSprite;

# OO interface
my $css = OCBNET::CSS3::Stylesheet->new;

my $code = <<EOF;

.test-01
{
	/* sprite: fam url(fam.png); */
}

.test-02
{
	/* sprite: lores url(lores.png); */
}

.test-03
{
	/* css-ref: lores */
	/* css-id: lores-ref */
}

.test-04
{
	/* css-ref: lores-ref */
}

EOF


$rv = $css->parse($code);

is    ($css->child(0)->option('css-id'),          'fam',              'parse css-id from sprite');
is    ($css->child(0)->option('sprite-image'),    'url(fam.png)',     'parse sprite-image');

is    ($css->child(1)->option('css-id'),          'lores',            'parse css-id from sprite');
is    ($css->child(1)->option('sprite-image'),    'url(lores.png)',   'parse sprite-image');

is    ($css->child(2)->option('css-id'),          'lores-ref',        'parse css-id from sprite');
is    ($css->child(2)->option('sprite-image'),    'url(lores.png)',   'parse sprite-image');

is    ($css->child(3)->option('css-id'),          undef,              'parse css-id from sprite');
is    ($css->child(3)->option('sprite-image'),    'url(lores.png)',   'parse sprite-image');
