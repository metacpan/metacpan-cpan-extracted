use strict;
use warnings;
use Test::More tests => 7;
use NetHack::PriceID 'priceid';

my @p = priceid (
    charisma => 10,
    in       => 'buy',
    amount   => 106,
    type     => '?',
);
is_deeply(\@p,
    ['blank paper', 'enchant armor', 'enchant weapon', 'remove curse'],
        'Buying a scroll for $106 at 10 charisma');

@p = priceid (
    charisma => 10,
    in       => 'buy',
    amount   => 106,
    type     => '?',
    out      => 'base',
);
is_deeply(\@p, [60, 80], 'Buying a scroll for $106 at 10 charisma, out=base');

@p = priceid (
    charisma => 10,
    in       => 'buy',
    amount   => 80,
    type     => '?',
);
is_deeply(\@p, ['blank paper', 'enchant weapon'],
    'Buying a scroll for $80 at 10 charisma');

@p = priceid (
    charisma => 10,
    in       => 'buy',
    amount   => 141,
    type     => '?',
);
is_deeply(\@p, ['enchant armor', 'remove curse'],
    'Buying a scroll for $141 at 10 charisma');

@p = priceid (
    charisma => 10,
    in       => 'buy',
    amount   => 888,
    type     => '/',
);
is_deeply(\@p, ['death', 'wishing'], 'Buying a wand for $888 at 10 charisma');

@p = priceid (
    charisma => 3,
    in       => 'buy',
    amount   => 1000,
    type     => '/',
);
is_deeply(\@p, ['death', 'wishing'], 'Buying a wand for $1000 at 3 charisma');

@p = priceid (
    charisma => 25,
    in       => 'buy',
    amount   => 333,
    type     => '/',
);
is_deeply(\@p, ['death', 'wishing'], 'Buying a wand for $333 at 25 charisma');

