#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 6;

use PDF::Builder;

# tests 1 and 4 will mention PNG_IPL if Image::PNG::Libpng is installed
# and usable, otherwise they will display just PNG. you can use this
# information if you are not sure about the status of Image::PNG::Libpng.

# Filename 3 tests

my $pdf = PDF::Builder->new('-compress' => 'none');

# -silent shuts off one-time warning for rest of run
my $png = $pdf->image_png('t/resources/1x1.png', -silent => 1);
if ($png->usesLib() == 1) {
    isa_ok($png, 'PDF::Builder::Resource::XObject::Image::PNG_IPL',
        q{$pdf->image_png(filename)});
} else {
    isa_ok($png, 'PDF::Builder::Resource::XObject::Image::PNG',
        q{$pdf->image_png(filename)});
}

is($png->width(), 1,
   q{Image from filename has a width});

my $gfx = $pdf->page->gfx();
$gfx->image($png, 72, 144, 216, 288);
like($pdf->stringify(), qr/q 216 0 0 288 72 144 cm \S+ Do Q/,
     q{Add PNG to PDF});

# Filehandle 2 tests

$pdf = PDF::Builder->new();
open my $fh, '<', 't/resources/1x1.png';
$png = $pdf->image_png($fh);
if ($png->usesLib() == 1) {
    isa_ok($png, 'PDF::Builder::Resource::XObject::Image::PNG_IPL',
        q{$pdf->image_png(filehandle)});
} else {
    isa_ok($png, 'PDF::Builder::Resource::XObject::Image::PNG',
        q{$pdf->image_png(filehandle)});
}

is($png->width(), 1,
   q{Image from filehandle has a width});

close $fh;

# Missing file 1 test

$pdf = PDF::Builder->new();
eval { $pdf->image_png('t/resources/this.file.does.not.exist') };
ok($@, q{Fail fast if the requested file doesn't exist});

1;
