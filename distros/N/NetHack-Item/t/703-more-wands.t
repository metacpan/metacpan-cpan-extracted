#!/usr/bin/env perl
use lib 't/lib';
use Test::NetHack::Item;

my $pool = NetHack::ItemPool->new;

my $spiked = $pool->new_item("a spiked wand");
ok($spiked->tracker, "got a tracker");
ok($spiked->tracker->engrave_useful, "engraving spiked would be useful");
is($pool->trackers->possible_appearances_of('wand of fire'), 27, 'all wand appearances can be fire');

$spiked->tracker->rule_out('wand of fire');
is($pool->trackers->possible_appearances_of('wand of fire'), 26, 'appearances of wand of fire does not include spiked');
done_testing;
