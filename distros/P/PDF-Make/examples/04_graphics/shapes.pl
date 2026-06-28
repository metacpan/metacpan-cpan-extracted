#!/usr/bin/perl
# Feature: Shapes
# Description: Demonstrates basic shape primitives: boxes, lines, circles,
#              ellipses, and pie segments.
# Output: corpus/feature_examples/04_graphics/shapes.pdf

use strict;
use warnings;
use lib 'lib', 'blib/lib', 'blib/arch';
use File::Path qw(make_path);
use PDF::Make::Builder;

make_path('corpus/feature_examples/04_graphics');

my $pdf = PDF::Make::Builder->new(
    file_name => 'corpus/feature_examples/04_graphics/shapes',
);

$pdf->add_page(page_size => 'Letter', padding => 36)
    ->add_h1(text => 'Shape Primitives')
    ->add_h2(text => 'Boxes')
    ->add_box(fill_colour => '#3b82f6', w => 280, h => 24)
    ->add_box(fill_colour => '#10b981', w => 220, h => 24)
    ->add_box(fill_colour => '#f59e0b', w => 160, h => 24)
    ->add_h2(text => 'Lines')
    ->add_line(fill_colour => '#111827', type => 'solid')
    ->add_line(fill_colour => '#2563eb', type => 'dashed')
    ->add_line(fill_colour => '#dc2626', type => 'dots')
    ->add_h2(text => 'Circle, Ellipse, Pie')
    ->add_circle(fill_colour => '#8b5cf6', x => 120, y => 520, r => 36)
    ->add_ellipse(fill_colour => '#14b8a6', x => 270, y => 520, w => 120, h => 60)
    ->add_pie(fill_colour => '#f97316', x => 430, y => 520, r => 40, rx => 0, ry => 120);

$pdf->save();
print "Created corpus/feature_examples/04_graphics/shapes.pdf\n";
