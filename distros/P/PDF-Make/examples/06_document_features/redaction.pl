#!/usr/bin/perl
# Feature: Redaction
# Description: Demonstrates marking regions for redaction and applying redactions.
#              Redacted areas are blacked out with optional overlay text.
# Output: corpus/feature_examples/06_document_features/redaction.pdf

use strict;
use warnings;
use lib 'lib', 'blib/lib', 'blib/arch';
use File::Path qw(make_path);
use PDF::Make::Builder;

make_path('corpus/feature_examples/06_document_features');

my $pdf = PDF::Make::Builder->new(
    file_name => 'corpus/feature_examples/06_document_features/redaction',
);

$pdf->add_page(page_size => 'Letter')
    ->add_h1(text => 'Document Redaction')
    ->add_text(text => 'This document demonstrates PDF redaction capabilities.')
    ->add_text(text => 'Sensitive information below has been marked for redaction.');

$pdf->add_text(text => 'Employee: John Smith')
    ->add_text(text => 'SSN: 123-45-6789')
    ->add_text(text => 'Salary: $125,000')
    ->add_text(text => 'Department: Engineering');

# Mark the two sensitive lines for redaction.  Rects are [x0, y0, x1, y1]
# in PDF user-space (bottom-left origin).  Baselines for the text lines
# above are roughly y=644 (SSN) and y=630 (Salary) at 9pt Helvetica, so
# each rect spans ~13pt vertically to cover the whole glyph box.
$pdf->mark_redaction(page => 0, rect => [18, 641,  98, 654],
                     overlay_text => 'REDACTED');           # SSN line
$pdf->mark_redaction(page => 0, rect => [18, 627,  95, 640],
                     overlay_text => 'REDACTED');           # Salary line

# Burn the redactions into the content stream (drops the underlying
# text operators so extraction can't recover the bytes) and sanitize
# document metadata.
$pdf->apply_redactions->sanitize;

# Note: apply_redactions() and sanitize() burn the redaction annotations
# into the page content, permanently removing the underlying data.
# They are available but omitted here to keep the example simple.
# In production: $pdf->apply_redactions->sanitize;

$pdf->add_text(text => '')
    ->add_text(text => 'Two redaction annotations have been placed on this page.')
    ->add_text(text => 'A conforming viewer will show them as redaction marks.');

$pdf->save();
print "Created corpus/feature_examples/06_document_features/redaction.pdf\n";
