#!/usr/bin/perl
# Feature: Layout Rows and Cells
# Description: Demonstrates weighted row/cell layout, backgrounds, borders,
#              and per-cell text content.
# Output: corpus/feature_examples/02_layout/layout_rows_and_cells.pdf

use strict;
use warnings;
use lib 'lib', 'blib/lib', 'blib/arch';
use File::Path qw(make_path);
use PDF::Make::Builder;

make_path('corpus/feature_examples/02_layout');

my $pdf = PDF::Make::Builder->new(
    file_name => 'corpus/feature_examples/02_layout/layout_rows_and_cells',
    configure => {
        h1 => { font => { size => 24, line_height => 30, colour => '#1a1a2e' } },
        h2 => { font => { size => 14, line_height => 20, colour => '#0f3460' } },
    },
);

$pdf->add_page(page_size => 'Letter', padding => 36)
    ->add_h1(text => 'Layout: Rows and Cells')
    ->add_h2(text => '2-Column Equal Split');

my $layout1 = $pdf->layout;
my $row1 = $layout1->row(height => 90);
$row1->cell(weight => 1, bg => '#ebf5fb', border => '#aed6f1', pad => 10)
     ->text('Left Cell', size => 12, colour => '#2c3e50')
     ->text('Equal width with padding and border.', size => 9, colour => '#555');
$row1->cell(weight => 1, bg => '#fef9e7', border => '#f9e79f', pad => 10)
     ->text('Right Cell', size => 12, colour => '#2c3e50')
     ->text('Same weight means same width.', size => 9, colour => '#555');
$layout1->render;

$pdf->add_h2(text => '3-Column Weighted (1:2:1)');
my $layout2 = $pdf->layout;
my $row2 = $layout2->row(height => 90);
$row2->cell(weight => 1, bg => '#e8f8f5', border => '#a3e4d7', pad => 8)
     ->text('Side', size => 10, colour => '#1a5276');
$row2->cell(weight => 2, bg => '#ffffff', border => '#d5d8dc', pad => 8)
     ->text('Main', size => 10, colour => '#1a5276')
     ->text('Center cell gets double width via weight => 2.', size => 9, colour => '#444');
$row2->cell(weight => 1, bg => '#fdedec', border => '#f5b7b1', pad => 8)
     ->text('Side', size => 10, colour => '#1a5276');
$layout2->render;

$pdf->save();
print "Created corpus/feature_examples/02_layout/layout_rows_and_cells.pdf\n";
