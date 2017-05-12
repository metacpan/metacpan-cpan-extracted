#!/usr/bin/env perl
use lib 't/lib';
use Test::NetHack::Item;
use Test::Fatal;

my $pool = NetHack::ItemPool->new;

my $glass = $pool->new_item("a glass wand");
my $steel = $pool->new_item("a steel wand");

$_->tracker->rule_out_all_but('wand of nothing', 'wand of light')
    for $glass, $steel;

$glass->tracker->rule_out('wand of nothing');

is($glass->identity, 'wand of light');
is($steel->identity, 'wand of nothing');

my $short = $pool->new_item("a short wand");

like(exception {
    $short->tracker->identify_as('wand of light');
}, qr/^wand of light is not a possibility for short wand/);

done_testing;
