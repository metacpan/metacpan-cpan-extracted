use strict;
use warnings;
use Test::More tests => 42;
use NetHack::PriceID 'priceid';

sub any_is {
    my $expected = shift;
    local $Test::Builder::Level += 1;

    ok(grep { $_ eq $expected } @_)
        or do {
            diag "Element $expected not in";
            diag "List (" . join(', ', @_) . ")";
        };
}

my @prices = qw/106 120 133 146 160 173 186/;
my @surcharge = qw/141 160 177 194 213 230 248/;

for my $enchantment (0 .. 6) {
    my $name = $enchantment
             ? "+$enchantment cornuthaum"
             : "cornuthaum";

    my @p = priceid (
        in     => 'base',
        amount => 80 + 10 * $enchantment,
        type   => '[',
    );
    any_is($name, @p);

    @p = priceid (
        in       => 'buy',
        amount   => $prices[$enchantment],
        type     => 'helmet',
        charisma => 10,
    );
    any_is($name, @p);

    @p = priceid (
        in       => 'buy',
        amount   => $surcharge[$enchantment],
        type     => 'armor',
        charisma => 10,
    );
    any_is($name, @p);

    @p = priceid (
        in     => 'sell',
        amount => 40 + 5 * $enchantment,
        type   => '[',
    );
    any_is($name, @p);

    my $sell = 40 + 5 * $enchantment;

    @p = priceid (
        in     => 'sell',
        amount => $sell,
        type   => '[',
    );
    any_is($name, @p);

    @p = priceid (
        in     => 'sell',
        amount => $sell - int($sell / 4),
        type   => '[',
    );
    any_is($name, @p);
}
