#!/usr/bin/env perl
use lib 't/lib';
use Test::NetHack::Item;

my $pool = NetHack::ItemPool->new;

my $vellum = $pool->new_item("a blessed vellum spellbook");
my $blank = $pool->new_item("a spellbook of blank paper");

my $vellum_tracker = $vellum->tracker;
my $blank_tracker = $blank->tracker;

$vellum_tracker->rule_out("spellbook of healing");

ok($vellum->tracker, "got a tracker");
ok($vellum->tracker->includes_possibility("spellbook of jumping"), "includes jumping");
ok(!$vellum->tracker->includes_possibility("spellbook of healing"), "doesn't include healing");
ok(!$vellum->tracker->includes_possibility("spellbook of blank paper"), "doesn't include blank spellbook");
is($vellum->appearance, "vellum spellbook", "appearance");
is($vellum->identity, undef, "identity");
is($vellum->quantity, 1, "quantity");
is($vellum->buc, "blessed", "buc");

$vellum->did_blank;
is($vellum->tracker, $blank_tracker, "is now the blank tracker");
is($vellum->appearance, "plain spellbook", "appearance");
is($vellum->identity, "spellbook of blank paper", "identity");
is($vellum->quantity, 1, "quantity");
is($vellum->buc, "blessed", "buc");

my $new_vellum = $pool->new_item("a vellum spellbook");
is($new_vellum->tracker, $vellum_tracker, "tracker");
ok($new_vellum->tracker->includes_possibility("spellbook of jumping"), "includes jumping");
ok(!$new_vellum->tracker->includes_possibility("spellbook of healing"), "doesn't include healing");
ok(!$new_vellum->tracker->includes_possibility("spellbook of blank paper"), "doesn't include blank spellbook");

done_testing;

