#!/usr/bin/env perl
use lib 't/lib';
use Test::NetHack::Item;

my %base = (
    slot            => undef,
    quantity        => 1,
    buc             => undef,
    greased         => 0,
    poisoned        => 0,
    burnt           => 0,
    corroded        => 0,
    rotted          => 0,
    rusty           => 0,
    proofed         => undef,
    used            => 0,
    eaten           => 0,
    diluted         => 0,
    item            => undef,
    enchantment     => undef,
    generic         => '',
    specific        => '',
    recharges       => undef,
    charges         => undef,
    candles         => 0,
    lit             => 0,
    laid            => 0,
    chained         => 0,
    quivered        => 0,
    offhand         => 0,
    wielded         => 0,
    offhand_wielded => 0,
    worn            => 0,
    cost            => 0,
    is_custom_fruit => 0,
);

my %all_checks = (
    "a long sword" => {
        item => "long sword",
        type => 'weapon',
    },
    "the blessed +1 Excalibur" => {
        item        => "Excalibur",
        enchantment => '+1',
        buc         => 'blessed',
        type        => 'weapon',
    },
    "a - 2 cursed -3 darts" => {
        item        => "dart",
        slot        => 'a',
        buc         => 'cursed',
        enchantment => '-3',
        quantity    => 2,
        type        => 'weapon',
    },
    "a diluted potion called foo named bar" => {
        item     => "potion",
        generic  => 'foo',
        specific => 'bar',
        diluted  => 1,
        type     => 'potion',
    },
    "a - a +0 katana (weapon in hand)" => {
        item        => "katana",
        slot        => 'a',
        enchantment => '+0',
        wielded     => 1,
        type        => 'weapon',
    },
    "b - a +0 wakizashi (alternate weapon; not wielded)" => {
        item        => "short sword",
        slot        => 'b',
        enchantment => '+0',
        offhand     => 1,
        type        => 'weapon',
    },
    "b - a +0 wakizashi (wielded in other hand)" => {
        item            => "short sword",
        slot            => 'b',
        enchantment     => '+0',
        offhand_wielded => 1,
        type        => 'weapon',
    },
    "p - a partly used candle (lit)" => {
        item => 'candle',
        lit  => 1,
        slot => 'p',
        used => 1,
        type => 'tool',
    },
    "p - a partly used candle" => {
        item => 'candle',
        slot => 'p',
        used => 1,
        type => 'tool',
    },
    "o - a candelabrum (no candles attached)" => {
        item    => 'candelabrum',
        slot    => 'o',
        type    => 'tool',
    },
    "o - a candelabrum (1 candle attached)" => {
        item    => 'candelabrum',
        slot    => 'o',
        candles => 1,
        type    => 'tool',
    },
    "o - a candelabrum (1 candle, lit)" => {
        item    => 'candelabrum',
        lit     => 1,
        slot    => 'o',
        candles => 1,
        type    => 'tool',
    },
    "q - a poisoned dart (in quiver)" => {
        item     => 'dart',
        slot     => 'q',
        poisoned => 1,
        quivered => 1,
        type     => 'weapon',
    },
    "r - a potion of holy water" => {
        slot => 'r',
        item => 'potion of water',
        buc  => 'holy',
        type => 'potion',
    },
    "r - a potion of unholy water" => {
        slot => 'r',
        item => 'potion of water',
        buc  => 'unholy',
        type => 'potion',
    },
    "r - an uncursed potion of water" => {
        slot => 'r',
        item => 'potion of water',
        buc  => 'uncursed',
        type => 'potion',
    },
    "u - a partly eaten food ration" => {
        slot  => 'u',
        item  => 'food ration',
        eaten => 1,
        type  => 'food',
    },
    "p - a scroll labeled TEMOV" => {
        slot => 'p',
        item => 'scroll labeled TEMOV',
        type => 'scroll',
    },
    "p - a blessed scroll of charging" => {
        slot => 'p',
        item => 'scroll of charging',
        buc  => 'blessed',
        type => 'scroll',
    },
    "q - a fizzy potion" => {
        slot => 'q',
        item => 'fizzy potion',
        type => 'potion',
    },
    "q - an uncursed potion of oil" => {
        slot => 'q',
        item => 'potion of oil',
        buc  => 'uncursed',
        type => 'potion',
    },
    "o - a wand of wishing (0:3)" => {
        slot      => 'o',
        item      => 'wand of wishing',
        charges   => 3,
        recharges => 0,
        type      => 'wand',
    },
    "o - a wand of wishing (0:0)" => {
        slot      => 'o',
        item      => 'wand of wishing',
        recharges => 0,
        charges   => 0,
        type      => 'wand',
    },
    "o - a wand of wishing (1:3)" => {
        slot      => 'o',
        item      => 'wand of wishing',
        charges   => 3,
        recharges => 1,
        type      => 'wand',
    },
    "t - a wand of wishing (0:-1)" => {
        slot      => 't',
        item      => 'wand of wishing',
        charges   => -1,
        recharges => 0,
        type      => 'wand',
    },
    "o - a wand of wishing (1:-1)" => {
        slot      => 'o',
        item      => 'wand of wishing',
        charges   => -1,
        recharges => 1,
        type      => 'wand',
    },
    "v - a bag of tricks (0:14)" => {
        slot      => 'v',
        item      => 'bag of tricks',
        charges   => 14,
        recharges => 0,
        type      => 'tool',
    },
    "x - a heavy iron ball (chained to you)" => {
        slot    => 'x',
        item    => 'heavy iron ball',
        chained => 1,
        type    => 'other',
    },
    "o - a cockatrice egg (laid by you)" => {
        slot => 'o',
        item => 'cockatrice egg',
        laid => 1,
        type => 'food',
    },
    "b - an uncursed burnt +0 cloak of magic resistance (being worn)" => {
        slot        => 'b',
        item        => 'cloak of magic resistance',
        enchantment => '+0',
        worn        => 1,
        burnt       => 1,
        buc         => 'uncursed',
        type        => 'armor',
    },
    "e - an uncursed ring of conflict" => {
        slot => 'e',
        buc  => 'uncursed',
        item => 'ring of conflict',
        type => 'ring',
    },
    "e - an uncursed ring of conflict (on left hand)" => {
        slot => 'e',
        buc  => 'uncursed',
        item => 'ring of conflict',
        worn => 'left',
        type => 'ring',
    },
    "e - an uncursed ring of conflict (on right hand)" => {
        slot => 'e',
        buc  => 'uncursed',
        item => 'ring of conflict',
        worn => 'right',
        type => 'ring',
    },
    "h - 100 gold pieces" => {
        slot     => 'h',
        item     => 'gold piece',
        quantity => 100,
        type     => 'gold',
    },
    "l - a turquoise spellbook" => {
        slot => 'l',
        item => 'turquoise spellbook',
        type => 'spellbook',
    },
    "l - a blessed spellbook of force bolt" => {
        slot => 'l',
        item => 'spellbook of force bolt',
        buc  => 'blessed',
        type => 'spellbook',
    },
    "q - a hexagonal amulet" => {
        slot => 'q',
        item => "hexagonal amulet",
        type => "amulet",
    },
    "q - an uncursed amulet versus poison" => {
        slot => 'q',
        item => "amulet versus poison",
        buc  => 'uncursed',
        type => "amulet",
    },
    "r - blue gem" => {
        slot => 'r',
        item => "blue gem",
        type => "gem",
    },
    "r - an uncursed turquoise stone" => {
        slot => 'r',
        item => "turquoise stone",
        buc  => "uncursed",
        type => "gem",
    },
    "tin (7 zorkmids)" => {
        item => "tin",
        type => "food",
        cost => 7,
    },
);

my $pool = NetHack::ItemPool->new;

for my $description (sort keys %all_checks) {
    my $checks = { %base, %{ $all_checks{$description} } };

    my $item = NetHack::Item->new(raw => $description, pool => $pool);
    my $stats = $item->extract_stats($description);
    is_deeply($stats, $checks, "'$description'");
}

done_testing;
