#!/usr/bin/perl
# Feature: Layers (OCG)
# Description: Demonstrates optional content groups (layers) with visible and
#              hidden content that can be toggled in supporting PDF viewers.
# Output: corpus/feature_examples/04_graphics/layers.pdf

use strict;
use warnings;
use lib 'lib', 'blib/lib', 'blib/arch';
use File::Path qw(make_path);
use PDF::Make::Builder;

make_path('corpus/feature_examples/04_graphics');

my $pdf = PDF::Make::Builder->new(
    file_name => 'corpus/feature_examples/04_graphics/layers',
);

$pdf->add_page(page_size => 'Letter', padding => 36)
    ->add_h1(text => 'Layer Demo (OCG)')
    ->add_text(text => 'Open layer controls in your PDF viewer to toggle visibility.');

$pdf->add_layer('Visible Layer', visible => 1)
    ->add_layer('Hidden Layer',  visible => 0)
    ->add_h2(text => 'Visible Layer Content')
    ->begin_layer('Visible Layer')
    ->add_line(fill_colour => '#2563eb', type => 'solid')
    ->add_text(text => 'This content is initially visible.')
    ->end_layer
    ->add_h2(text => 'Hidden Layer Content')
    ->begin_layer('Hidden Layer')
    ->add_line(fill_colour => '#dc2626', type => 'dashed')
    ->add_text(text => 'This content starts hidden.')
    ->end_layer;

$pdf->save();
print "Created corpus/feature_examples/04_graphics/layers.pdf\n";
