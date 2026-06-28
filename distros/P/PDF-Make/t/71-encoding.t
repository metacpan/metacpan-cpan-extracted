#!/usr/bin/perl
# Phase 2 — /Encoding + /Differences resolution.
#
# Verifies that simple (non-CID) fonts decode correctly through the
# Adobe Glyph List when a /Differences array is present, and that our
# own generated PDFs (which all use /Differences for Std14 fonts) still
# extract their literal text content.

use strict;
use warnings;
use Test::More;

BEGIN { use_ok('PDF::Make::Builder') }

my $b = PDF::Make::Builder->new(file_name => '/tmp/encoding_scratch');

# ── Round-trip: hello world ──────────────────────────────

SKIP: {
    my $f = 't/fixtures/hello_world.pdf';
    skip "$f not present", 2 unless -f $f;

    my $r = $b->extract_structured($f, page => 0);
    my $text = $r->to_string // '';
    like($text, qr/Hello,?\s*World/i, 'hello_world extracts');

    my @words = $r->text_positions;
    cmp_ok(scalar @words, '>=', 2, "yields >= 2 words (got @{[scalar @words]})");
}

# ── Round-trip: fonts_and_ttf (multiple families + differences) ──

SKIP: {
    my $f = 't/fixtures/feature_examples/01_basics/fonts_and_ttf.pdf';
    skip "$f not present", 3 unless -f $f;

    my $r = $b->extract_structured($f, page => 0);
    my $text = $r->to_string // '';
    $text =~ s/\s+/ /g;

    like($text, qr/Helvetica/, 'Helvetica reference present');
    like($text, qr/Times/,     'Times reference present');
    like($text, qr/Courier/,   'Courier reference present');
}

# ── Round-trip: styled_text (custom colors + sizes) ──────

SKIP: {
    my $f = 't/fixtures/feature_examples/01_basics/styled_text.pdf';
    skip "$f not present", 1 unless -f $f;

    my $r = $b->extract_structured($f, page => 0);
    my $text = $r->to_string // '';
    ok(length($text) > 10, "styled_text extracts content (len=@{[length $text]})");
}

# ── ASCII sanity: no U+FFFD mojibake in simple PDFs ──────

SKIP: {
    my $f = 't/fixtures/feature_examples/01_basics/multi_page.pdf';
    skip "$f not present", 1 unless -f $f;

    my $r = $b->extract_structured($f, page => 0);
    my $text = $r->to_string // '';

    # Count replacement chars — should be near-zero for ASCII-only content
    my $mojibake = () = $text =~ /\x{FFFD}/g;
    is($mojibake, 0, "no U+FFFD replacement chars in ASCII PDF (got $mojibake)");
}

# ── Encoded PDF with embedded-TTF subset + /Differences ──

SKIP: {
    my $f = 't/fixtures/feature_examples/01_basics/hello_world.pdf';
    skip "$f not present", 1 unless -f $f;

    # For subset fonts, the glyph names in /Differences (if any) should
    # round-trip through the AGL. Verify no U+0000 slots surface as glyphs.
    my $r = $b->extract_structured($f, page => 0);
    my @words = $r->text_positions;
    my $zero = 0;
    for my $w (@words) {
        for my $ch (split //, $w->{text}) {
            $zero++ if ord($ch) == 0;
        }
    }
    is($zero, 0, 'no U+0000 codepoints leaked from unresolved /Differences slots');
}

done_testing;
