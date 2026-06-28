#!/usr/bin/perl
# Feature: Watermarks
# Description: Demonstrates text watermark overlay across the document.
# Output: corpus/feature_examples/04_graphics/watermarks.pdf

use strict;
use warnings;
use lib 'lib', 'blib/lib', 'blib/arch';
use File::Path qw(make_path);
use PDF::Make::Builder;

make_path('corpus/feature_examples/04_graphics');

my $pdf = PDF::Make::Builder->new(
    file_name => 'corpus/feature_examples/04_graphics/watermarks',
);

$pdf->add_page(page_size => 'Letter', padding => 36)
    ->add_h1(text => 'Watermark Example')
    ->add_text(text => 'This page contains a diagonal DRAFT watermark.');

$pdf->add_page()
    ->add_h1(text => 'Second Page')
    ->add_text(text => 'Watermark applies across pages in this document.');

$pdf->add_watermark(
    text     => 'DRAFT',
    opacity  => 0.05,
    rotation => 45,
    size     => 72,
    color    => [0, 0, 1],
);

$pdf->save();
print "Created corpus/feature_examples/04_graphics/watermarks.pdf\n";
