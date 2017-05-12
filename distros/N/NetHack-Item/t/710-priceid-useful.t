#!/usr/bin/env perl
use lib 't/lib';
use Test::NetHack::Item;

my $pool = NetHack::ItemPool->new;

my $spiked = $pool->new_item("a spiked wand");
ok($spiked->tracker->engrave_useful, "engraving spiked would be useful");
ok($spiked->tracker->priceid_useful, "price id would be useful too");

$spiked->tracker->rule_out_all_but('wand of sleep', 'wand of death');

ok(!$spiked->tracker->engrave_useful, "bugs stopped moving");
ok($spiked->tracker->priceid_useful, "price id would still be useful");

my $balsa = $pool->new_item("a balsa wand");
$balsa->tracker->rule_out_all_but('wand of cancellation', 'wand of teleportation', 'wand of make invisible');

ok(!$balsa->tracker->engrave_useful, "engraving vanished");
ok($balsa->tracker->priceid_useful, "price id would still be useful");

$balsa->tracker->rule_out('wand of cancellation', 'wand of teleportation');
ok(!$balsa->tracker->priceid_useful, "price id won't distinguish tele vs canc");

my $glass = $pool->new_item("a glass wand");
$glass->tracker->rule_out_all_but('wand of wishing', 'wand of death');

ok($glass->tracker->engrave_useful, "engraving still useful");
ok(!$glass->tracker->priceid_useful, "price id not useful any more");

done_testing;

