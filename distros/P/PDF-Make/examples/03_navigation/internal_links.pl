#!/usr/bin/perl
# Feature: Internal Links
# Description: Demonstrates add_link(page => ...) rectangular hotspots that
#              jump between pages in the same document.
# Output: corpus/feature_examples/03_navigation/internal_links.pdf

use strict;
use warnings;
use lib 'lib', 'blib/lib', 'blib/arch';
use File::Path qw(make_path);
use PDF::Make::Builder;

make_path('corpus/feature_examples/03_navigation');

my $pdf = PDF::Make::Builder->new(
    file_name => 'corpus/feature_examples/03_navigation/internal_links',
);

# Page 1: menu
$pdf->add_page(page_size => 'Letter')
    ->add_h1(text => 'Internal Link Menu')
    ->add_text(text => 'Click the boxes to jump to target pages.');

# Draw clickable boxes with centered page number labels (bottom-left coords)
$pdf->add_box(fill_colour => '#3b82f6', x => 72, y => 140, w => 220, h => 28)
    ->add_text(text => 'Page 2', x => 72, y => 160, w => 220, align => 'center',
               font => { size => 12, colour => '#ffffff' })
    ->add_box(fill_colour => '#10b981', x => 72, y => 180, w => 220, h => 28)
    ->add_text(text => 'Page 3', x => 72, y => 200, w => 220, align => 'center',
               font => { size => 12, colour => '#ffffff' })
    ->add_box(fill_colour => '#f59e0b', x => 72, y => 220, w => 220, h => 28)
    ->add_text(text => 'Page 4', x => 72, y => 240, w => 220, align => 'center',
               font => { size => 12, colour => '#ffffff' });

# Pages 2-4: destinations
$pdf->add_page()->add_h1(text => 'Destination: Page 2')->add_text(text => 'Linked from the blue box on page 1.');
$pdf->add_page()->add_h1(text => 'Destination: Page 3')->add_text(text => 'Linked from the green box on page 1.');
$pdf->add_page()->add_h1(text => 'Destination: Page 4')->add_text(text => 'Linked from the amber box on page 1.');

# Add links after all destination pages exist; attach to page index 0
$pdf->add_link(page => 1, on_page => 0, x => 72, y => 140, w => 220, h => 28)
    ->add_link(page => 2, on_page => 0, x => 72, y => 180, w => 220, h => 28)
    ->add_link(page => 3, on_page => 0, x => 72, y => 220, w => 220, h => 28);

$pdf->save();
print "Created corpus/feature_examples/03_navigation/internal_links.pdf\n";
