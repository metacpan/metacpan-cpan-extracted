#!/usr/bin/perl
# Feature: Color Spaces
# Description: Demonstrates selecting a calibrated color space and drawing
#              colored content.
# Output: corpus/feature_examples/04_graphics/color_spaces.pdf

use strict;
use warnings;
use lib 'lib', 'blib/lib', 'blib/arch';
use File::Path qw(make_path);
use PDF::Make::Builder;

make_path('corpus/feature_examples/04_graphics');

my $pdf = PDF::Make::Builder->new(
    file_name => 'corpus/feature_examples/04_graphics/color_spaces',
);

$pdf->add_page(page_size => 'Letter', padding => 36)
    ->add_h1(text => 'Color Space Example')
    ->add_text(text => 'The document switches to sRGB before drawing color samples.')
    ->set_color_space('sRGB')
    ->add_box(fill_colour => '#ef4444', w => 240, h => 24)
    ->add_box(fill_colour => '#22c55e', w => 240, h => 24)
    ->add_box(fill_colour => '#3b82f6', w => 240, h => 24)
    ->add_text(text => 'Red, green, and blue samples are rendered under sRGB context.');

$pdf->save();
print "Created corpus/feature_examples/04_graphics/color_spaces.pdf\n";
