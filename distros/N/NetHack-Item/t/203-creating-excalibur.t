#!/usr/bin/env perl
use lib 't/lib';
use Test::NetHack::Item;

my $pool = NetHack::ItemPool->new;

my $long_sword = $pool->new_item("a long sword");
ok(!$long_sword->is_artifact, "not an artifact yet");

$long_sword->specific_name("Excalibur");
ok($long_sword->is_artifact, "now an artifact");

is($long_sword->identity, 'long sword');
is($long_sword->appearance, 'long sword');

is($pool->artifacts->{"Excalibur"}, $long_sword, "we're now tracking Excalibur");

$pool->new_item("+5 Excalibur");
is($long_sword->enchantment, '+5', "successfully incorporated");
is($pool->get_artifact("Excalibur")->enchantment, '+5', "successfully incorporated");

done_testing;
