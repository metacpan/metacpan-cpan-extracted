#!/usr/bin/env perl
use lib 't/lib';
use Test::NetHack::Item;

my $pool = NetHack::ItemPool->new;
my $excalibur = $pool->new_item("the +1 Excalibur");

is($excalibur->identity,   "long sword");
is($excalibur->appearance, "long sword");
is($excalibur->artifact,   "Excalibur");

is($pool->artifacts->{"Excalibur"}, $excalibur, "we're now tracking Excalibur");

my $other_excalibur = $pool->new_item("the +1 Excalibur");
is($excalibur, $other_excalibur, "same Excalibur");

my $plus_three_excalibur = $pool->new_item("the +3 Excalibur");
is($excalibur, $plus_three_excalibur, "same Excalibur, even with a different enchantment");
is($plus_three_excalibur->enchantment, '+3', "new enchantment incorporated");
is($excalibur->enchantment, '+3', "new enchantment incorporated into existing instances of Excalibur too");

my $blessed_excalibur = $pool->new_item("the blessed +3 Excalibur");
is($excalibur, $blessed_excalibur, "same Excalibur, even with a different enchantment");
is($blessed_excalibur->enchantment, '+3', "same enchantment");
is($excalibur->enchantment, '+3', "same enchantment");

my $other_pool = NetHack::ItemPool->new;
my $other_game_excalibur = $other_pool->new_item("the cursed -5 Excalibur");

isnt($excalibur, $other_game_excalibur, "new pool, new Excalibur");

is($other_game_excalibur->enchantment, -5);
is($other_game_excalibur->buc, 'cursed');

is($excalibur->enchantment, '+3', "new game's Excalibur doesn't affect ours");
is($excalibur->buc, 'blessed', "new game's Excalibur doesn't affect ours, but the previous one did");

my $magicbane = $pool->new_item("Magicbane");
is($magicbane->identity,   "athame");
is($magicbane->appearance, "athame");
is($magicbane->artifact,   "Magicbane");

done_testing;
