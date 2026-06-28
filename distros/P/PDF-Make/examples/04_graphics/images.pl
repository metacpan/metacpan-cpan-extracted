#!/usr/bin/perl
# Feature: Images
# Description: Demonstrates embedding JPEG and PNG images when available.
#              If sample images are missing, the PDF still renders fallback text.
# Output: corpus/feature_examples/04_graphics/images.pdf

use strict;
use warnings;
use lib 'lib', 'blib/lib', 'blib/arch';
use File::Path qw(make_path);
use PDF::Make::Builder;

make_path('corpus/feature_examples/04_graphics');

my $jpg = 'corpus/images/test.jpg';
my $png = 'corpus/images/test.png';

my $pdf = PDF::Make::Builder->new(
    file_name => 'corpus/feature_examples/04_graphics/images',
);

$pdf->add_page(page_size => 'Letter', padding => 36)
    ->add_h1(text => 'Image Embedding')
    ->add_text(text => 'This example embeds sample images from corpus/images when present.');

if (-f $jpg) {
    $pdf->add_h2(text => 'JPEG')
        ->add_image(image => $jpg, w => 240);
} else {
    $pdf->add_text(text => "JPEG sample not found at $jpg");
}

if (-f $png) {
    $pdf->add_h2(text => 'PNG')
        ->add_image(image => $png, w => 240);
} else {
    $pdf->add_text(text => "PNG sample not found at $png");
}

$pdf->save();
print "Created corpus/feature_examples/04_graphics/images.pdf\n";
