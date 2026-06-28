#!/usr/bin/perl
# Phase 9 — Ligature expansion.
#
# Verifies that /ToUnicode CMap mappings from a single glyph code to
# multiple Unicode codepoints (e.g. `<FB03>` → `<0066 0066 0069>` for
# the "ffi" ligature) emit one glyph record per codepoint, so searches
# and to_string() reconstruct the individual characters.

use strict;
use warnings;
use Test::More;

BEGIN { use_ok('PDF::Make::Builder') }

my $fixture = 't/fixtures/ligature_test.pdf';
plan skip_all => "$fixture not found" unless -f $fixture;

my $b = PDF::Make::Builder->new(file_name => '/tmp/lig_scratch');

# ── ffi ligature expands to three codepoints ────────────

my $r = $b->extract_structured($fixture, page => 0);
my @w = $r->text_positions;
cmp_ok(scalar @w, '>=', 1, 'extraction yielded at least one word');

my $text = $r->to_string // '';
chomp $text;

is($text, 'office',
   "ffi ligature expanded to 'ffi' (got '$text')");

# Search sanity: a substring starting with 'ff' should be locatable
ok(index($text, 'ff') >= 0, "'ff' substring present after ligature expansion");
ok(index($text, 'fi') >= 0, "'fi' substring present after ligature expansion");

# ── Length sanity: "office" is 6 chars (not 4 as it would be if we ──
# picked uni_out[0] only for the ffi ligature: "o"+"f"+"c"+"e") ──────
is(length($text), 6, "word length = 6 characters");

# ── Word width still reflects the ligature glyph's advance ──────────
# (not 6 × average char, since we split uniformly within ligature)
my ($word) = @w;
cmp_ok($word->{w}, '>', 20,
       "word width reasonable (got $word->{w} pt)");

# ── Regression: single-codepoint mappings still produce one glyph ──

SKIP: {
    my $f = 't/fixtures/hello_world.pdf';
    skip "$f not found", 1 unless -f $f;
    my $hr = $b->extract_structured($f, page => 0);
    my @hw = $hr->text_positions;
    is(scalar @hw, 2, 'hello_world still 2 words');
}

# ── placement.pdf still extracts correctly ──────────────

SKIP: {
    my $f = 't/fixtures/placement.pdf';
    skip "$f not found", 1 unless -f $f;
    my $pr = $b->extract_structured($f, page => 1);
    my @pw = $pr->text_positions;
    my $found = grep { $_->{text} eq 'File' } @pw;
    ok($found, 'placement.pdf "File" still extracted');
}

done_testing;
