#!/usr/bin/perl
# Feature: Notes and Stamps
# Description: Demonstrates text annotations (sticky notes) and stamp-like
#              overlays using boxes and text positioning.
# Output: corpus/feature_examples/05_forms_and_annotations/notes_and_stamps.pdf

use strict;
use warnings;
use lib 'lib', 'blib/lib', 'blib/arch';
use File::Path qw(make_path);
use PDF::Make::Builder;

make_path('corpus/feature_examples/05_forms_and_annotations');

my $pdf = PDF::Make::Builder->new(
    file_name => 'corpus/feature_examples/05_forms_and_annotations/notes_and_stamps',
);

$pdf->add_page(page_size => 'Letter')
    ->add_h1(text => 'Notes and Stamps');

# ── Document body ───────────────────────────────────────
$pdf->add_lines(
    'This document demonstrates annotation-style overlays.',
    'Below are examples of stamp-like elements created with boxes and positioned text.',
);

# ── "APPROVED" stamp ────────────────────────────────────
$pdf->add_stamp(text => 'APPROVED', bg_colour => '#dcfce7',
                colour => '#16a34a', size => 24, x => 72, y => 580, w => 200, h => 50);

# ── "DRAFT" stamp ───────────────────────────────────────
$pdf->add_stamp(text => 'DRAFT', bg_colour => '#fef3c7',
                colour => '#d97706', size => 24, x => 72, y => 480, w => 200, h => 50);

# ── "CONFIDENTIAL" banner ──────────────────────────────
$pdf->add_stamp(text => 'CONFIDENTIAL', bg_colour => '#fee2e2',
                colour => '#dc2626', size => 20, x => 72, y => 380, w => 428, h => 40);

# ── Note-style callout ─────────────────────────────────
$pdf->add_note(
    lines     => [
        'Note: Review section 3.2 before final sign-off.',
        { text => '-- QA Team, 2026-04-21', size => 9, colour => '#b45309', italic => 1 },
    ],
    bg_colour => '#fffbeb',
    colour    => '#92400e',
    x => 72, y => 280, w => 300, h => 70,
);

$pdf->save();
print "Created corpus/feature_examples/05_forms_and_annotations/notes_and_stamps.pdf\n";
