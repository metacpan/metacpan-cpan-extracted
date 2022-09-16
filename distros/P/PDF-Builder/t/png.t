#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 9;

use PDF::Builder;

# tests 1 and 7 will mention PNG_IPL if Image::PNG::Libpng is installed
# and usable, otherwise they will display just PNG. you can use this
# information if you are not sure about the status of Image::PNG::Libpng.

# (1,2,3) Filename 

my $pdf = PDF::Builder->new('compress' => 'none');

# silent shuts off one-time warning for rest of run
my $png = $pdf->image_png('t/resources/1x1.png', 'silent' => 1);
if ($png->usesLib() == 1) {
    isa_ok($png, 'PDF::Builder::Resource::XObject::Image::PNG_IPL',
        q{$pdf->image_png(filename)});
} else {
    isa_ok($png, 'PDF::Builder::Resource::XObject::Image::PNG',
        q{$pdf->image_png(filename)});
}

is($png->width(), 1,
   q{Image from filename has a width});

my $gfx = $pdf->page()->gfx();
$gfx->image($png, 72, 144, 216, 288);
like($pdf->to_string(), qr/q 216 0 0 288 72 144 cm \S+ Do Q/,
     q{Add PNG to PDF});

# (4) RGBA PNG file

$pdf = PDF::Builder->new();

$png = $pdf->image_png('t/resources/test-rgba.png');
if ($png->usesLib() == 1) {
    isa_ok($png, 'PDF::Builder::Resource::XObject::Image::PNG_IPL',
           q{$pdf->image_png(filename)});
} else {
    isa_ok($png, 'PDF::Builder::Resource::XObject::Image::PNG',
           q{$pdf->image_png(filename)});
}

my $page = $pdf->page();
$page->mediabox(840,600);
$gfx=$page->gfx();
$gfx->image($png,134,106,510,281);
my $rgba1_pdf_string = $pdf->to_string();

# (5,6) RGBA PNG file Pure Perl

$pdf = PDF::Builder->new();
my $png2 = $pdf->image_png('t/resources/test-rgba.png', 'nouseIPL'=>1);
isa_ok($png2, 'PDF::Builder::Resource::XObject::Image::PNG',
       q{$pdf->image_png(filename), pure Perl});

my $page2 = $pdf->page();
$page2->mediabox(840,600);
my $gfx2 = $page2->gfx();
$gfx2->image($png2,134,106,510,281);
my $rgba2_pdf_string = $pdf->to_string();

is(substr($rgba1_pdf_string, 0, 512), substr($rgba2_pdf_string, 0, 512),
     q{XS and pure perl PDFs are the same});

# (7,8) Filehandle

$pdf = PDF::Builder->new();
open my $fh, '<', 't/resources/1x1.png' or
    die "Can't open file t/resources/1x1.png";
$png = $pdf->image($fh);  # use convenience function on this one
if ($png->usesLib() == 1) {
    isa_ok($png, 'PDF::Builder::Resource::XObject::Image::PNG_IPL',
        q{$pdf->image(filehandle)});
} else {
    isa_ok($png, 'PDF::Builder::Resource::XObject::Image::PNG',
        q{$pdf->image(filehandle)});
}

is($png->width(), 1,
   q{Image from filehandle has a width});

close $fh;

# (9) Missing file

$pdf = PDF::Builder->new();
eval { $pdf->image_png('t/resources/this.file.does.not.exist') };
ok($@, q{Fail fast if the requested file doesn't exist});

1;
