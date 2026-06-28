#!/usr/bin/perl
# Feature: Attachments
# Description: Demonstrates embedding file attachments in a PDF document.
#              Attached files appear in the PDF viewer's attachment panel.
# Output: corpus/feature_examples/06_document_features/attachments.pdf

use strict;
use warnings;
use lib 'lib', 'blib/lib', 'blib/arch';
use File::Path qw(make_path);
use PDF::Make::Builder;

make_path('corpus/feature_examples/06_document_features');

my $pdf = PDF::Make::Builder->new(
    file_name => 'corpus/feature_examples/06_document_features/attachments',
);

$pdf->add_page(page_size => 'Letter')
    ->add_h1(text => 'PDF Attachments')
    ->add_text(text => 'This document has embedded file attachments.')
    ->add_text(text => 'Check your PDF viewer\'s attachment panel to see them.');

# Attach inline data as a file
$pdf->attach(
    name        => 'sample_data.csv',
    data        => "Name,Score\nAlice,95\nBob,87\nCharlie,92\n",
    description => 'Sample CSV data',
    mime_type   => 'text/csv',
);

# Attach another inline file
$pdf->attach(
    name        => 'config.json',
    data        => qq({"version": "1.0", "format": "pdf", "engine": "PDF::Make"}),
    description => 'Configuration metadata',
    mime_type   => 'application/json',
);

$pdf->add_text(text => 'Attached files:')
    ->add_text(text => '  1. sample_data.csv  - CSV data with three rows')
    ->add_text(text => '  2. config.json      - JSON configuration metadata');

$pdf->save();
print "Created corpus/feature_examples/06_document_features/attachments.pdf\n";
