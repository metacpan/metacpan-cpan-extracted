use Test::More tests => 8;

use warnings;
use strict;

use PDF::Builder;

# Filename

my $pdf = PDF::Builder->new('-compress' => 'none');

my $tiff = $pdf->image_tiff('t/resources/1x1.tif');
isa_ok($tiff, 'PDF::Builder::Resource::XObject::Image::TIFF',
       q{$pdf->image_tiff(filename)});

is($tiff->width(), 1,
   q{Image from filename has a width});

my $gfx = $pdf->page->gfx();
$gfx->image($tiff, 72, 144, 216, 288);
like($pdf->stringify(), qr/q 216 0 0 288 72 144 cm \S+ Do Q/,
     q{Add TIFF to PDF});

# Filehandle

$pdf = PDF::Builder->new();
open my $fh, '<', 't/resources/1x1.tif';
$tiff = $pdf->image_tiff($fh);
isa_ok($tiff, 'PDF::Builder::Resource::XObject::Image::TIFF',
       q{$pdf->image_tiff(filehandle)});

is($tiff->width(), 1,
   q{Image from filehandle has a width});

close $fh;

# LZW Compression

$pdf = PDF::Builder->new('-compress' => 'none');

my $lzw_tiff = $pdf->image_tiff('t/resources/1x1-lzw.tif');
isa_ok($lzw_tiff, 'PDF::Builder::Resource::XObject::Image::TIFF',
       q{$pdf->image_tiff(), LZW compression});

$gfx = $pdf->page->gfx();
$gfx->image($lzw_tiff, 72, 360, 216, 432);

like($pdf->stringify(), qr/q 216 0 0 432 72 360 cm \S+ Do Q/,
     q{Add TIFF to PDF});

# Missing file

$pdf = PDF::Builder->new();
eval { $pdf->image_tiff('t/resources/this.file.does.not.exist') };
ok($@, q{Fail fast if the requested file doesn't exist});
