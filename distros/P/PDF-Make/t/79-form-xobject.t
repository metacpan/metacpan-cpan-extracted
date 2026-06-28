#!/usr/bin/perl
# Phase 7 — Form XObject recursion.
#
# Verifies that text drawn inside Form XObjects (via `/FormN Do`) is
# captured during structured extraction, with the form's Matrix applied
# to positioning and the form's /Resources overlaid on the page's.

use strict;
use warnings;
use Test::More;

BEGIN { use_ok('PDF::Make::Builder') }

my $fixture = 't/fixtures/form_xobject_test.pdf';
plan skip_all => "$fixture not found" unless -f $fixture;

my $b = PDF::Make::Builder->new(file_name => '/tmp/form_scratch');

# ── Basic recursion ─────────────────────────────────────

my $r = $b->extract_structured($fixture, page => 0);
my @w = $r->text_positions;

# Main-page content
my $flat = join ' ', map { $_->{text} } @w;
like($flat, qr/Hello/, 'main-page text present');
like($flat, qr/from/,  'main-page text continues');
like($flat, qr/page/,  'main-page text complete');

# Form XObject content (was invisible pre-Phase-7)
like($flat, qr/TextInForm!/,
     "Form XObject text captured via Do recursion");

cmp_ok(scalar @w, '>=', 4, "at least 4 words (3 page + 1+ from form)");

# ── Form-XObject text positioning ──────────────────────

my ($form_text) = grep { $_->{text} eq 'TextInForm!' } @w;
ok($form_text, "found form text word");

SKIP: {
    skip 'TextInForm! not found', 2 unless $form_text;
    # The form was placed at rect [72, 150, 272, 200] on the page.
    # After Matrix transform the text should appear somewhere reasonable.
    cmp_ok($form_text->{x}, '>=', 0, "form text x >= 0");
    cmp_ok($form_text->{y}, '>',  50, "form text y reasonable");
}

# ── No regressions on plain PDFs ───────────────────────

SKIP: {
    my $plain = 't/fixtures/hello_world.pdf';
    skip "$plain not found", 2 unless -f $plain;

    my $hr = $b->extract_structured($plain, page => 0);
    my @hw = $hr->text_positions;
    is(scalar @hw, 2, 'hello_world still 2 words');
    is($hw[0]{text}, 'Hello,', 'first word still "Hello,"');
}

# ── Hex string decoding (Phase-7 side-fix) ──────────────
# PyMuPDF emits Tj strings as hex (<48656c6c6f>). Our tokenizer
# preserves the hex flag; op_Tj now decodes them before the
# visitor sees raw bytes.

SKIP: {
    my $pm = 't/fixtures/placement.pdf';
    skip "$pm not found", 1 unless -f $pm;

    my $pr = $b->extract_structured($pm, page => 1);
    my @pw = $pr->text_positions;
    my $flat = join ' ', map { $_->{text} } @pw;
    $flat =~ s/\s+//g;
    like($flat, qr/SampleDataFile/, 'placement.pdf still decodes correctly');
}

done_testing;
