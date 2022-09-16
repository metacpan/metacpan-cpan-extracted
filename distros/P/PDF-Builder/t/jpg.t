#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 5;

use PDF::Builder;

my $pdf = PDF::Builder->new('compress' => 'none');

my $jpg = $pdf->image_jpeg('t/resources/1x1.jpg');
isa_ok($jpg, 'PDF::Builder::Resource::XObject::Image::JPEG',
       q{$pdf->image_jpeg()});

my $gfx = $pdf->page()->gfx();
$gfx->image($jpg, 72, 144, 216, 288);
like($pdf->to_string(), qr/q 216 0 0 288 72 144 cm \S+ Do Q/,
     q{Add JPG to PDF});

# Filehandle

$pdf = PDF::Builder->new();
open my $fh, '<', 't/resources/1x1.jpg';
$jpg = $pdf->image($fh);  # use convenience function
isa_ok($jpg, 'PDF::Builder::Resource::XObject::Image::JPEG',
       q{$pdf->image(filehandle)});

is($jpg->width(), 1,
   q{Image from filehandle has a width});

close $fh;

# Missing file

$pdf = PDF::Builder->new();
eval { $pdf->image_jpeg('t/resources/this.file.does.not.exist') };
ok($@, q{Fail fast if the requested file doesn't exist});

1;
