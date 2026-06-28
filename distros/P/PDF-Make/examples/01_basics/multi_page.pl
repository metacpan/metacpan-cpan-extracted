#!/usr/bin/perl
# Feature: Multi-Page Document
# Description: Demonstrates creating multiple pages and navigating between them.
#              Shows how to add new pages and manage content across pages.
# Output: corpus/feature_examples/01_basics/multi_page.pdf

use strict;
use warnings;
use lib 'lib';
use PDF::Make::Builder;

my $pdf = PDF::Make::Builder->new(
    file_name => 'corpus/feature_examples/01_basics/multi_page',
);

$pdf->add_page(page_size => 'Letter')
    ->add_h1(text => 'Chapter 1: Introduction')
    ->add_text(text => 'This is the first page of a multi-page document.')
    ->add_text(text => 'Each page can contain different content and formatting.')
    ->add_page()
    ->add_h1(text => 'Chapter 2: Content')
    ->add_text(text => 'This is the second page.')
    ->add_text(text => 'Notice how we can add new pages with add_page().')
    ->add_text(text => 'Each page starts fresh with default formatting.')
    ->add_page()
    ->add_h1(text => 'Chapter 3: More Pages')
    ->add_text(text => 'This is the third page.')
    ->add_h2(text => 'Section 3.1')
    ->add_text(text => 'We can use heading levels to structure content.')
    ->add_h2(text => 'Section 3.2')
    ->add_text(text => 'Pages automatically flow to maintain layout.')
    ->add_page()
    ->add_h1(text => 'Chapter 4: Conclusion')
    ->add_text(text => 'This is the final page.')
    ->add_text(text => 'Multi-page documents are useful for reports, manuals, and long documents.');

$pdf->save();
print "Created corpus/feature_examples/01_basics/multi_page.pdf\n";
