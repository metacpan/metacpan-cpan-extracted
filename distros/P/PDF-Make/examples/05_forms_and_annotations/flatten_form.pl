#!/usr/bin/perl
# Feature: Flatten Form
# Description: Demonstrates creating form fields and then flattening them into
#              static content. After flattening, fields are no longer interactive
#              but their visual appearance is preserved in the page content.
# Output: corpus/feature_examples/05_forms_and_annotations/flatten_form.pdf

use strict;
use warnings;
use lib 'lib', 'blib/lib', 'blib/arch';
use File::Path qw(make_path);
use PDF::Make::Builder;

make_path('corpus/feature_examples/05_forms_and_annotations');

my $pdf = PDF::Make::Builder->new(
    file_name => 'corpus/feature_examples/05_forms_and_annotations/flatten_form',
);

$pdf->add_page(page_size => 'Letter')
    ->add_h1(text => 'Flattened Form')
    ->add_text(text => 'These fields were created and then flattened into static content.');

# Create fields with default values (cursor-relative positioning)
$pdf->add_text(text => 'Name:')
    ->add_field(type => 'text', name => 'name', default => 'John Smith')
    ->add_text(text => 'Approved:')
    ->add_field(type => 'checkbox', name => 'approved', w => 18, h => 18,
                default => 'Yes');

# Flatten all form fields into page content
$pdf->flatten_form;

$pdf->save();
print "Created corpus/feature_examples/05_forms_and_annotations/flatten_form.pdf\n";
