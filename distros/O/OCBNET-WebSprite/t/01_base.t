# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 1;
BEGIN { use_ok('OCBNET::WebSprite') };

my $rv;

use OCBNET::CSS3::Styles::References;
use OCBNET::CSS3::Styles::WebSprite;

# OO interface
my $css = OCBNET::CSS3::Stylesheet->new;

my $code = <<EOF;

EOF

__DATA__

$rv = $css->parse($code);

is    ($css->child(0)->option('css-id'),          'fam',              'parse css-id from sprite');
is    ($css->child(0)->option('sprite-image'),    'url(fam.png)',     'parse sprite-image');

is    ($css->child(1)->option('css-id'),          'lores',            'parse css-id from sprite');
is    ($css->child(1)->option('sprite-image'),    'url(lores.png)',   'parse sprite-image');

is    ($css->child(2)->option('css-id'),          'lores-ref',        'parse css-id from sprite');
is    ($css->child(2)->option('sprite-image'),    'url(lores.png)',   'parse sprite-image');

is    ($css->child(3)->option('css-id'),          undef,              'parse css-id from sprite');
is    ($css->child(3)->option('sprite-image'),    'url(lores.png)',   'parse sprite-image');
