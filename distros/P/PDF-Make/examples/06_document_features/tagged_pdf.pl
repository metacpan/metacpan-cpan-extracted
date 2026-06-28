#!/usr/bin/perl
# Feature: Tagged PDF / Accessibility
# Description: Demonstrates enable_tagging() which creates a structure tree.
#              Headings become /H1-/H6 elements and text becomes /P elements,
#              making the PDF accessible to screen readers.
# Output: corpus/feature_examples/06_document_features/tagged_pdf.pdf

use strict;
use warnings;
use lib 'lib', 'blib/lib', 'blib/arch';
use File::Path qw(make_path);
use PDF::Make::Builder;

make_path('corpus/feature_examples/06_document_features');

my $pdf = PDF::Make::Builder->new(
    file_name => 'corpus/feature_examples/06_document_features/tagged_pdf',
);

# Enable tagging BEFORE adding content so structure elements are created
$pdf->enable_tagging;

$pdf->add_page(page_size => 'Letter')
    ->add_h1(text => 'Accessible PDF Document')
    ->add_text(text => 'This PDF uses structural tags for accessibility. '
                     . 'Screen readers can navigate using the heading hierarchy.');

$pdf->add_h2(text => 'Introduction')
    ->add_text(text => 'Tagged PDFs include a logical structure tree that maps '
                     . 'visual content to semantic elements like headings, '
                     . 'paragraphs, lists, and figures.');

$pdf->add_h2(text => 'Benefits')
    ->add_text(text => '1. Screen reader navigation via heading structure')
    ->add_text(text => '2. Content reflow for different screen sizes')
    ->add_text(text => '3. Copy/paste preserves reading order')
    ->add_text(text => '4. Compliance with PDF/UA accessibility standard');

$pdf->add_h3(text => 'Implementation')
    ->add_text(text => 'Call enable_tagging() before adding content. '
                     . 'Headings (H1-H6) and text (P) are tagged automatically.');

$pdf->save();
print "Created corpus/feature_examples/06_document_features/tagged_pdf.pdf\n";
