#!perl -T
use strict;
use warnings;

use Test::More tests => 4;

use Test::Exception;
use SVG::Rasterize;

sub typeglobs {
    $SVG::Rasterize::DPI = 30;
    is($SVG::Rasterize::PX_PER_IN, 30, 'setting DPI');

    my $rasterize = SVG::Rasterize->new;
    is($rasterize->px_per_in, 30, 'getting object variable');
    $rasterize->dpi(120);
    is($rasterize->dpi, 120, 'setting object variable dpi');
    is($rasterize->px_per_in, 120, 'setting object variable dpi');
}

typeglobs;
