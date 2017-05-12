#!/usr/bin/env perl
use lib 't/lib';
use Test::NetHack::Item;

my $pool = NetHack::ItemPool->new;

my $foobie = $pool->new_item("3 blessed scrolls labeled FOOBIE BLETCH");
my $blank = $pool->new_item("a scroll of blank paper");

my $foobie_tracker = $foobie->tracker;
my $blank_tracker = $blank->tracker;

$foobie_tracker->rule_out("scroll of charging");

ok($foobie->tracker, "got a tracker");
ok($foobie->tracker->includes_possibility("scroll of identify"), "includes identify");
ok(!$foobie->tracker->includes_possibility("scroll of charging"), "doesn't include charging");
ok(!$foobie->tracker->includes_possibility("scroll of blank paper"), "doesn't include blank scroll");
is($foobie->appearance, "scroll labeled FOOBIE BLETCH", "appearance");
is($foobie->identity, undef, "identity");
is($foobie->quantity, 3, "quantity");
is($foobie->buc, "blessed", "buc");

$foobie->did_blank;
is($foobie->tracker, $blank_tracker, "is now the blank tracker");
is($foobie->appearance, "unlabeled scroll", "appearance");
is($foobie->identity, "scroll of blank paper", "identity");
is($foobie->quantity, 3, "quantity");
is($foobie->buc, "blessed", "buc");

my $new_foobie = $pool->new_item("a scroll labeled FOOBIE BLETCH");
is($new_foobie->tracker, $foobie_tracker, "tracker");
ok($new_foobie->tracker->includes_possibility("scroll of identify"), "includes identify");
ok(!$new_foobie->tracker->includes_possibility("scroll of charging"), "doesn't include charging");
ok(!$new_foobie->tracker->includes_possibility("scroll of blank paper"), "doesn't include blank scroll");

done_testing;

