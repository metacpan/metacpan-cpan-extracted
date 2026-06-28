#!/usr/bin/perl
# Phase 10 — Column reading order.
#
# Verifies that two-column layouts extract column-1-top-to-bottom followed
# by column-2-top-to-bottom, not interleaved by y-coordinate as a naive
# sort by baseline would produce.

use strict;
use warnings;
use Test::More;

BEGIN { use_ok('PDF::Make::Builder') }

my $fixture = 't/fixtures/two_column_test.pdf';
plan skip_all => "$fixture not found" unless -f $fixture;

my $b = PDF::Make::Builder->new(file_name => '/tmp/col_scratch');

# ── Synthetic two-column fixture ────────────────────────

my $r = $b->extract_structured($fixture, page => 0);
my @w = $r->text_positions;

my @texts = map { $_->{text} } @w;

# Find indices of the distinctive column-marker words
my %idx;
for my $i (0 .. $#texts) {
    $idx{$texts[$i]} = $i;
}

ok(exists $idx{'Left1A'},  "Left1A present");
ok(exists $idx{'Right3B'}, "Right3B present");

# Left column top-to-bottom comes before right column top-to-bottom
cmp_ok($idx{'Left1A'},  '<', $idx{'Left2A'},  'left: Left1A before Left2A');
cmp_ok($idx{'Left2A'},  '<', $idx{'Left3A'},  'left: Left2A before Left3A');
cmp_ok($idx{'Left3A'},  '<', $idx{'Right1B'}, 'all left before all right');
cmp_ok($idx{'Right1B'}, '<', $idx{'Right2B'}, 'right: Right1B before Right2B');
cmp_ok($idx{'Right2B'}, '<', $idx{'Right3B'}, 'right: Right2B before Right3B');

# Full-width header still comes first
cmp_ok($idx{'HEADER'}, '<', $idx{'Left1A'}, 'header before body');

# ── placement.pdf: real-world 2-column ──────────────────

SKIP: {
    my $f = 't/fixtures/placement.pdf';
    skip "$f not found", 2 unless -f $f;

    my $pr = $b->extract_structured($f, page => 1);
    my @pw = $pr->text_positions;

    # Count how many left-column words appear before the first right-column word
    my $first_right = -1;
    for my $i (0 .. $#pw) {
        if ($pw[$i]{x} > 250) { $first_right = $i; last; }
    }
    cmp_ok($first_right, '>', 20,
           "at least 20 left-column words precede the first right-column word");

    # After the first right-column word, no more left-column words
    my $leakage = 0;
    if ($first_right >= 0) {
        for my $i ($first_right .. $#pw) {
            $leakage++ if $pw[$i]{x} < 250;
        }
    }
    cmp_ok($leakage, '<=', 15,
           "few stray left-column words after right-column starts (got $leakage)");
}

# ── Single-column PDFs unaffected ───────────────────────

SKIP: {
    my $f = 't/fixtures/hello_world.pdf';
    skip "$f not found", 2 unless -f $f;
    my $hr = $b->extract_structured($f, page => 0);
    my @hw = $hr->text_positions;
    is(scalar @hw, 2, 'hello_world still 2 words');
    is($hw[0]{text}, 'Hello,', 'first word still "Hello,"');
}

done_testing;
