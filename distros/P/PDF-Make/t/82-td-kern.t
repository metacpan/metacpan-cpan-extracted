#!/usr/bin/perl
# Phase 8 — Text-matrix advance synchronization.
#
# Verifies that the interpreter advances the text matrix using the visitor's
# real glyph widths, so consecutive Tj/TJ calls land at consistent positions
# in user space. Pre-Phase-8 the interpreter used a 0.6-em placeholder which
# drifted away from actual glyph positions, creating phantom gaps between
# runs and causing cross-run words to fragment.

use strict;
use warnings;
use Test::More;

BEGIN { use_ok('PDF::Make::Builder') }

my $fixture = 't/fixtures/placement.pdf';
plan skip_all => "$fixture not found" unless -f $fixture;

my $b = PDF::Make::Builder->new(file_name => '/tmp/td_scratch');

# ── TJ-with-kern content: "Sample Data File" reconstitutes ──

my $r = $b->extract_structured($fixture, page => 1);
my @w = $r->text_positions;

my ($sample) = grep { $_->{text} eq 'Sample' } @w;
my ($data)   = grep { $_->{text} eq 'Data' } @w;
my ($file)   = grep { $_->{text} eq 'File' } @w;
my ($bm)     = grep { $_->{text} eq 'Bookmark' } @w;

ok($sample, "'Sample' extracted as one word");
ok($data,   "'Data' extracted as one word");
ok($file,   "'File' extracted as one word (was 'Fil'+'e' pre-Phase-8)");
ok($bm,     "'Bookmark' extracted as one word (was 'Book'+'mark')");

# ── Widths match PyMuPDF reference values ──

SKIP: {
    skip "'Sample' not found", 1 unless $sample;
    cmp_ok(abs($sample->{w} - 42.8), '<', 0.5,
           "'Sample' width ~42.8pt (PyMuPDF reference)");
}
SKIP: {
    skip "'Data' not found", 1 unless $data;
    cmp_ok(abs($data->{w} - 25.9), '<', 0.5,
           "'Data' width ~25.9pt");
}
SKIP: {
    skip "'File' not found", 1 unless $file;
    cmp_ok(abs($file->{w} - 20.6), '<', 0.5,
           "'File' width ~20.6pt");
}

# ── Positions match PyMuPDF reference ──

SKIP: {
    skip "'Data' not found", 2 unless $data;
    # PyMuPDF: Data rect=[103.8, 112.5, 129.7, 125.9]
    cmp_ok(abs($data->{x} - 103.8), '<', 1.0,
           "'Data' x ~103.8 (PyMuPDF reference)");
    # Data ends at x~129.7. File begins at x~133.1 — ~3pt gap = space.
    SKIP: { skip "'File' not found", 1 unless $file;
        cmp_ok(abs($file->{x} - 133.1), '<', 1.0,
               "'File' x ~133.1 (PyMuPDF reference)");
    }
}

# ── Word count sanity: should have dropped from pre-Phase-8 numbers ──

cmp_ok(scalar @w, '<', 115,
       "word count reduced (got @{[scalar @w]}, pre-Phase-8 was 130+)");

# ── No regressions on simple PDFs ──

SKIP: {
    my $f = 't/fixtures/hello_world.pdf';
    skip "$f not present", 2 unless -f $f;

    my $hr = $b->extract_structured($f, page => 0);
    my @hw = $hr->text_positions;
    is(scalar @hw, 2, 'hello_world still 2 words');
    is($hw[0]{text}, 'Hello,', 'first word still "Hello,"');
}

# ── Form XObject still works (Phase 7) ──

SKIP: {
    my $f = 't/fixtures/form_xobject_test.pdf';
    skip "$f not present", 1 unless -f $f;

    my $fr = $b->extract_structured($f, page => 0);
    my @fw = $fr->text_positions;
    my $found = grep { $_->{text} eq 'TextInForm!' } @fw;
    ok($found, 'Form XObject text still captured');
}

done_testing;
