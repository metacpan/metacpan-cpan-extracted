#!/usr/bin/perl
# Feature: Form Fields
# Description: Demonstrates interactive form fields: text inputs, checkboxes,
#              combo boxes, list boxes, and push buttons. Fields flow with the
#              cursor using x/y/w/h args (like add_text) rather than raw rects.
#              Open the generated PDF in a viewer to interact with the fields.
# Output: corpus/feature_examples/05_forms_and_annotations/form_fields.pdf

use strict;
use warnings;
use lib 'lib', 'blib/lib', 'blib/arch';
use File::Path qw(make_path);
use PDF::Make::Builder;

make_path('corpus/feature_examples/05_forms_and_annotations');

my $pdf = PDF::Make::Builder->new(
    file_name => 'corpus/feature_examples/05_forms_and_annotations/form_fields',
);

$pdf->add_page(page_size => 'Letter')
    ->add_h1(text => 'Interactive Form Fields');

# ── Text fields (cursor-relative, no rect needed) ──────
$pdf->add_h2(text => 'Text Input')
    ->add_text(text => 'Name:')
    ->add_field(type => 'text', name => 'full_name', default => 'Jane Doe')
    ->add_text(text => 'Email:')
    ->add_field(type => 'text', name => 'email');

# ── Checkboxes ─────────────────────────────────────────
$pdf->add_h2(text => 'Checkboxes')
    ->add_text(text => 'I agree to the terms:')
    ->add_field(type => 'checkbox', name => 'agree', w => 18, h => 18)
    ->add_text(text => 'Subscribe to newsletter:')
    ->add_field(type => 'checkbox', name => 'subscribe', w => 18, h => 18);

# ── Combo box (dropdown) ───────────────────────────────
$pdf->add_h2(text => 'Dropdown (Combo)')
    ->add_text(text => 'Country:')
    ->add_field(type => 'combo', name => 'country',
                options => ['United States', 'United Kingdom', 'Canada', 'Australia']);

# ── List box ────────────────────────────────────────────
$pdf->add_h2(text => 'List Box')
    ->add_text(text => 'Interests:')
    ->add_field(type => 'listbox', name => 'interests', h => 70,
                options => [['Programming', 'prog'], ['Design', 'design'],
                            ['Writing', 'write'], ['Music', 'music']]);

# ── Button ──────────────────────────────────────────────
$pdf->add_h2(text => 'Push Button')
    ->add_field(type => 'button', name => 'submit_btn', w => 130, h => 30,
                caption => 'Submit');

$pdf->save();
print "Created corpus/feature_examples/05_forms_and_annotations/form_fields.pdf\n";
