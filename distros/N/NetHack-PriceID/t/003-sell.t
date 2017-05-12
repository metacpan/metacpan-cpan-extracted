use strict;
use warnings;
use Test::More tests => 4;
use NetHack::PriceID 'priceid';

my @p = priceid (
    charisma => 10,
    in       => 'sell',
    amount   => 30,
    type     => '?',
);

is_deeply(\@p,
    ['blank paper', 'enchant armor', 'enchant weapon', 'remove curse'],
        'Selling a scroll for $30 at 10 charisma');

@p = priceid (
    charisma => 10,
    in       => 'sell',
    amount   => 23,
    type     => '?',
);

is_deeply(\@p,
    ['blank paper', 'enchant weapon'],
        'Selling a scroll for $23 at 10 charisma');

@p = priceid (
    charisma => 10,
    in       => 'sell',
    amount   => 40,
    type     => '?',
);

is_deeply(\@p,
    ['enchant armor', 'remove curse'],
        'Selling a scroll for $40 at 10 charisma');

@p = priceid (
    charisma => 18,
    in       => 'sell',
    amount   => 25,
    type     => '?',
);

is_deeply(\@p, ['light'], 'Selling a scroll for $25 at 18 charisma');

