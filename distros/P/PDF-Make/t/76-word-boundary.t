#!/usr/bin/perl
# Phase 5 — Kern-aware word-boundary heuristic.
#
# Verifies that words split across multiple Tj/Td operators (e.g. due to
# font changes within a word, TJ kerning, or subsetted fonts with missing
# /Widths) aggregate into single words when they should, without merging
# genuine inter-word spaces.

use strict;
use warnings;
use Test::More;

BEGIN { use_ok('PDF::Make::Builder') }

my $b = PDF::Make::Builder->new(file_name => '/tmp/wb_scratch');

# ── placement.pdf: encrypted PDF with subset fonts ──────
#
# The source content stream positions "Sample Data File" as three runs
# with font-change Tds between each letter group. Pre-Phase-5 this
# extracted as 5 fragments; post-Phase-5 it should be 3 words.

SKIP: {
    my $f = 't/fixtures/placement.pdf';
    skip "$f not found", 4 unless -f $f;

    my $r = $b->extract_structured($f, page => 1);
    my @w = $r->text_positions;

    my @texts = map { $_->{text} } @w;

    # Key assertion: "Data" must appear as a single word (not "D" + "ata")
    my $has_data = grep { $_ eq 'Data' } @texts;
    ok($has_data, "'Data' reconstituted from fragments (no 'D' + 'ata' split)");

    # "Bookmark" should reconstitute (was "Book" + "mark" pre-Phase-6/7)
    my $has_bookmark = grep { $_ eq 'Bookmark' } @texts;
    ok($has_bookmark, "'Bookmark' reconstituted via real TTF widths");

    # "Sample" should still be intact (was already single word before)
    my $has_sample = grep { $_ eq 'Sample' } @texts;
    ok($has_sample, "'Sample' still intact");

    # Total word count should be in a reasonable range. Accurate widths
    # can cause some cross-font-change words to split ("Fil"+"e"); that's
    # Phase 8 territory (Td-delta metadata).
    cmp_ok(scalar @w, '<=', 140,
           "word count reasonable (got @{[scalar @w]})");
}

# ── hello_world.pdf: simple ASCII PDF baseline ──────────
#
# Pre-Phase-5 this already extracted correctly. Verify we didn't merge
# "Hello," and "World!" into one word.

SKIP: {
    my $f = 't/fixtures/hello_world.pdf';
    skip "$f not found", 2 unless -f $f;

    my $r = $b->extract_structured($f, page => 0);
    my @w = $r->text_positions;
    is(scalar @w, 2, "hello_world still produces 2 words (no over-merge)");
    is_deeply([map { $_->{text} } @w], ['Hello,', 'World!'],
              "words preserved correctly");
}

# ── fonts_and_ttf.pdf: multi-font content ──────────────
#
# Mixed Std14 fonts. All words on each line should stay separate and
# none should merge across font changes.

SKIP: {
    my $f = 't/fixtures/feature_examples/01_basics/fonts_and_ttf.pdf';
    skip "$f not found", 2 unless -f $f;

    my $r = $b->extract_structured($f, page => 0);
    my $text = $r->to_string // '';

    # Should contain recognizable words — not an endless mash
    like($text, qr/\bHelvetica\b/, "'Helvetica' extracted as a word");
    like($text, qr/\bTimes\b/, "'Times' extracted as a word");
}

# ── Widths integration: heights + widths still correct ──

SKIP: {
    my $f = 't/fixtures/placement.pdf';
    skip "$f not found", 2 unless -f $f;

    my $r = $b->extract_structured($f, page => 1);
    my @w = $r->text_positions;

    my ($data) = grep { $_->{text} eq 'Data' } @w;
    SKIP: {
        skip "'Data' word not found", 2 unless $data;
        cmp_ok($data->{h}, '>', 6, "'Data' height realistic");
        cmp_ok($data->{w}, '>', 20,
               "'Data' width > 20pt (spans multiple glyph runs)");
    }
}

done_testing;
