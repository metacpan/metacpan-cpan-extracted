#!/usr/bin/env perl
use lib 't/lib';
use constant testing_method => 'spell';
use Test::NetHack::Item;

test_items(
    'spellbook of force bolt'      => 'force bolt',
    'spellbook of finger of death' => 'finger of death',
    'spellbook of jumping'         => 'jumping',

    'plain spellbook'              => undef,
    'spellbook of blank paper'     => undef,
    'Book of the Dead'             => undef,

    'papyrus spellbook'            => undef,
    'silver spellbook'             => undef,
    'dog eared spellbook'          => undef,
);

done_testing;
