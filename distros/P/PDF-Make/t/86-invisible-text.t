#!/usr/bin/perl
# Phase 11 — Invisible text (render mode 3) toggle.
#
# OCR'd PDFs layer text with Tr=3 ("invisible") beneath a rasterized page
# image so the document remains searchable. By default we include that
# text (preserving the search value); callers can opt out with
# invisible => 0 for visible-only extraction.

use strict;
use warnings;
use Test::More;

BEGIN { use_ok('PDF::Make::Builder') }

my $fixture = 't/fixtures/invisible_text_test.pdf';
plan skip_all => "$fixture not found" unless -f $fixture;

my $b = PDF::Make::Builder->new(file_name => '/tmp/inv_scratch');

# ── Default: include invisible text ─────────────────────

my $r_all = $b->extract_structured($fixture, page => 0);
my @w_all = $r_all->text_positions;
my %t_all = map { $_->{text} => 1 } @w_all;
ok($t_all{'VISIBLE_WORD'}, 'visible word extracted by default');
ok($t_all{'HIDDEN_WORD'},  'invisible (Tr=3) word extracted by default');

# ── invisible => 1 explicit: same as default ────────────

my $r_inc = $b->extract_structured($fixture, page => 0, invisible => 1);
my @w_inc = $r_inc->text_positions;
is(scalar @w_inc, scalar @w_all, 'invisible=1 yields same count as default');

# ── invisible => 0: visible-only ────────────────────────

my $r_vis = $b->extract_structured($fixture, page => 0, invisible => 0);
my @w_vis = $r_vis->text_positions;
my %t_vis = map { $_->{text} => 1 } @w_vis;
ok($t_vis{'VISIBLE_WORD'},     'visible word still present');
ok(!$t_vis{'HIDDEN_WORD'},     'hidden (Tr=3) word suppressed');
cmp_ok(scalar @w_vis, '<', scalar @w_all,
       "visible-only extraction drops at least one word");

# ── Regular PDFs unaffected by the flag ─────────────────

SKIP: {
    my $f = 't/fixtures/hello_world.pdf';
    skip "$f not found", 1 unless -f $f;

    my $r0 = $b->extract_structured($f, page => 0);
    my $r1 = $b->extract_structured($f, page => 0, invisible => 0);
    is(scalar($r0->text_positions), scalar($r1->text_positions),
       "flag has no effect on Tr=0 text");
}

done_testing;
