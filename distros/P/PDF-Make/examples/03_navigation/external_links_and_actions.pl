#!/usr/bin/perl
# Feature: External Links and Actions
# Description: Demonstrates URL links and named actions (NextPage, PrevPage,
#              FirstPage, LastPage) using add_link().
# Output: corpus/feature_examples/03_navigation/external_links_and_actions.pdf

use strict;
use warnings;
use lib 'lib', 'blib/lib', 'blib/arch';
use File::Path qw(make_path);
use PDF::Make::Builder;

make_path('corpus/feature_examples/03_navigation');

my $pdf = PDF::Make::Builder->new(
    file_name => 'corpus/feature_examples/03_navigation/external_links_and_actions',
);

$pdf->add_page(page_size => 'Letter')
    ->add_h1(text => 'External Links and Actions')
    ->add_text(text => 'Blue box: external URL. Green box: NextPage action.')
    ->add_box(fill_colour => '#2563eb', x => 20, y => 180, w => 240, h => 28)
    ->add_text(text => 'Open PDF::Make::Builder docs', x => 20, y => 200, w => 240, align => 'center',
               font => { size => 11, colour => '#ffffff' })
    ->add_box(fill_colour => '#059669', x => 20, y => 220, w => 240, h => 28)
    ->add_text(text => 'Next Page', x => 20, y => 240, w => 240, align => 'center',
               font => { size => 11, colour => '#ffffff' })
    ->add_link(url => 'https://metacpan.org/pod/PDF::Make::Builder', x => 20, y => 180, w => 240, h => 28)
    ->add_link(action => 'NextPage', x => 20, y => 220, w => 240, h => 28);

$pdf->add_page()
    ->add_h1(text => 'Action Targets')
    ->add_text(text => 'Use the boxes below for FirstPage, PrevPage, and LastPage actions.')
    ->add_box(fill_colour => '#7c3aed', x => 20, y => 120, w => 240, h => 28)
    ->add_text(text => 'First Page', x => 20, y => 140, w => 240, align => 'center',
               font => { size => 11, colour => '#ffffff' })
    ->add_box(fill_colour => '#dc2626', x => 20, y => 160, w => 240, h => 28)
    ->add_text(text => 'Previous Page', x => 20, y => 180, w => 240, align => 'center',
               font => { size => 11, colour => '#ffffff' })
    ->add_box(fill_colour => '#ea580c', x => 20, y => 200, w => 240, h => 28)
    ->add_text(text => 'Last Page', x => 20, y => 220, w => 240, align => 'center',
               font => { size => 11, colour => '#ffffff' })
    ->add_link(action => 'FirstPage', x => 20, y => 120, w => 240, h => 28)
    ->add_link(action => 'PrevPage',  x => 20, y => 160, w => 240, h => 28)
    ->add_link(action => 'LastPage',  x => 20, y => 200, w => 240, h => 28);

$pdf->add_page()
    ->add_h1(text => 'Final Page')
    ->add_text(text => 'LastPage action should jump here.');

$pdf->save();
print "Created corpus/feature_examples/03_navigation/external_links_and_actions.pdf\n";
