#!/usr/bin/perl
# Feature: Outlines / Bookmarks
# Description: Demonstrates add_outline() to build a hierarchical bookmark
#              tree visible in PDF viewers.
# Output: corpus/feature_examples/03_navigation/outlines_bookmarks.pdf

use strict;
use warnings;
use lib 'lib', 'blib/lib', 'blib/arch';
use File::Path qw(make_path);
use PDF::Make::Builder;

make_path('corpus/feature_examples/03_navigation');

my $pdf = PDF::Make::Builder->new(
    file_name => 'corpus/feature_examples/03_navigation/outlines_bookmarks',
);

$pdf->add_page(page_size => 'Letter')
    ->add_h1(text => 'Chapter 1')
    ->add_text(text => 'Open the bookmarks panel to inspect the outline tree.');

$pdf->add_page()
    ->add_h1(text => 'Chapter 2')
    ->add_text(text => 'Chapter 2 contains two nested sections in the outline tree.');

$pdf->add_page()
    ->add_h1(text => 'Appendix')
    ->add_text(text => 'Appendix demonstrates another top-level outline item.');

# Build a single visible root, then nest chapter bookmarks under it.
# This structure is rendered consistently across viewers.
$pdf->add_outline('Document', page => 0);

$pdf->add_outline('Chapter 1', page => 0, parent => 'Document');
$pdf->add_outline('Chapter 2', page => 1, parent => 'Document');
$pdf->add_outline('Appendix',  page => 2, parent => 'Document');

# Nested under Chapter 2
$pdf->add_outline('Section 2.1', page => 1, parent => 'Chapter 2');
$pdf->add_outline('Section 2.2', page => 1, parent => 'Chapter 2');

$pdf->save();
print "Created corpus/feature_examples/03_navigation/outlines_bookmarks.pdf\n";
