#!perl

use strict;
use warnings;

use Test::More tests => 4;
use Template::Plugin::xkcd;

my $xkcd = Template::Plugin::xkcd->new;
isa_ok( $xkcd, 'Template::Plugin::xkcd' );
can_ok( $xkcd, 'comic'                  );

like(
    $xkcd->comic,
    qr{<img src=".*\.png".*/>},
    'Got img',
);


like(
    $xkcd->comic(20),
    qr{<img src="https?://imgs\.xkcd\.com/comics/ferret\.jpg" alt=".*" />},
    'Got 20th comic image',
);

