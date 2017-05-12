use strict;
use warnings;
use Test::More tests => 3;
use NetHack::PriceID 'priceid';

my @p = priceid (
    charisma => 9,
    in       => 'sell',
    amount   => 20,
    type     => '?',
    dunce    => 1,
    tourist  => 1,
);
is_deeply(\@p,
    ['blank paper', 'enchant armor', 'enchant weapon', 'remove curse'],
        'Selling a scroll for $20 at 9 charisma, dunce and tourist');

@p = priceid (
    charisma => 9,
    in       => 'buy',
    amount   => 141,
    type     => '?',
    dunce    => 1,
    tourist  => 1,
);
is_deeply(\@p, ['blank paper', 'enchant weapon'],
    'Buying a scroll for $20 at 9 charisma, dunce and tourist');

@p = priceid (
    charisma => 9,
    in       => 'buy',
    amount   => 188,
    type     => '?',
    dunce    => 1,
    tourist  => 1,
    angry    => 1,
);
is_deeply(\@p, ['blank paper', 'enchant weapon'],
    'Buying a scroll for $188 at 9 charisma, angry; dunce; and tourist');

