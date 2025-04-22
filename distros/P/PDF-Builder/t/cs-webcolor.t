#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 2;

use PDF::Builder;

my $pdf = PDF::Builder->new('-compress' => 'none');

my $cs = $pdf->colorspace_web();
my $gfx = $pdf->page->gfx();

$gfx->strokecolor($cs, 3);
$gfx->move(72, 144);
$gfx->hline(288);
$gfx->stroke();

my $string = $pdf->to_string();

like($string, qr{\[ /Indexed /DeviceRGB 255},
     q{ColorSpace is present});

like($string, qr{CS 3 SC 72 144 m 288 144 l S},
     q{Indexed color is used for horizontal line});

1;
