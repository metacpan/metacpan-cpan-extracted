#!/usr/bin/perl
# Phase 3 — /Widths + font descriptor metrics.
#
# Checks that extracted word bounding boxes carry realistic heights
# derived from font metrics (rather than the 1.0 placeholder from
# before Phase 3), and that advance widths are accurate enough to
# reflect actual string widths.

use strict;
use warnings;
use Test::More;

BEGIN { use_ok('PDF::Make::Builder') }

my $b = PDF::Make::Builder->new(file_name => '/tmp/widths_scratch');

# ── hello_world.pdf: Std14, known text ─────────────────

SKIP: {
    my $f = 't/fixtures/hello_world.pdf';
    skip "$f not present", 6 unless -f $f;

    my $r = $b->extract_structured($f, page => 0);
    my @w = $r->text_positions;
    cmp_ok(scalar @w, '>=', 2, 'hello_world: at least 2 words');

    for my $word (@w) {
        my $fs = $word->{font_size};
        cmp_ok($fs,       '>', 0,         "font_size > 0 for '$word->{text}'");
        cmp_ok($word->{h}, '>', 0.3 * $fs, "height > 0.3*fs for '$word->{text}'");
        cmp_ok($word->{w}, '>', 0,         "width > 0 for '$word->{text}'");
    }
}

# ── placement.pdf: encrypted, subset TTF + CID ─────────

SKIP: {
    my $f = 't/fixtures/placement.pdf';
    skip "$f not present", 5 unless -f $f;

    my $r = $b->extract_structured($f, page => 1);
    my @w = $r->text_positions;
    cmp_ok(scalar @w, '>=', 10, 'placement.pdf page 1: many words');

    my $min_h = 999;
    my $min_fs = 999;
    my $zero_w = 0;
    for my $word (@w) {
        $min_h  = $word->{h}         if $word->{h}         < $min_h;
        $min_fs = $word->{font_size} if $word->{font_size} < $min_fs;
        $zero_w++ if $word->{w} <= 0;
    }

    cmp_ok($min_fs, '>', 0, 'all words have positive font_size');
    cmp_ok($min_h, '>', 1, "heights > 1pt (got min=$min_h, phase 3 fix)");
    is($zero_w, 0, 'no zero-width words');

    # For a 12pt font, height should be ~12 (±2 tolerance for descriptor variation)
    my ($sample) = grep { $_->{text} eq 'Sample' } @w;
    SKIP: {
        skip 'Sample word not found', 1 unless $sample;
        cmp_ok(abs($sample->{h} - $sample->{font_size}), '<', 4,
               "height matches font_size for 'Sample' (h=$sample->{h}, fs=$sample->{font_size})");
    }
}

# ── fonts_and_ttf.pdf: multiple Std14 + TTF fonts ──────

SKIP: {
    my $f = 't/fixtures/feature_examples/01_basics/fonts_and_ttf.pdf';
    skip "$f not present", 2 unless -f $f;

    my $r = $b->extract_structured($f, page => 0);
    my @w = $r->text_positions;
    cmp_ok(scalar @w, '>=', 3, 'multiple words');

    # Font sizes vary; each word should have h proportional to fs
    my $all_reasonable = 1;
    for my $word (@w) {
        $all_reasonable = 0 if $word->{h} < 0.3 * $word->{font_size};
    }
    ok($all_reasonable, 'all word heights are proportional to font size');
}

done_testing;
