use strict;
use warnings;
use Test::More tests => 12;
use NetHack::PriceID 'priceid';

eval {
    priceid (
        in       => 'buy',
        amount   => 50,
        type     => '?',
    );
};

ok($@);
like($@, qr/Calculating 'buy' prices requires that you set 'charisma'/);
like($@, qr/005-error/, "croak reports the correct file");

eval {
    priceid (
        in       => 'buy',
        charisma => 10,
        type     => '?',
    );
};

ok($@);
like($@, qr/Price IDing requires that you set 'amount'/);

eval {
    priceid (
        in       => 'buy',
        charisma => 10,
        amount   => 50,
    );
};

ok($@);
like($@, qr/Price IDing requires that you set 'type'/);

eval {
    priceid (
        in       => 'buy',
        charisma => 10,
        amount   => 50,
        type     => 'album',
    );
};

ok($@);
like($@, qr/Unknown item type: album/);

my @p = priceid (
    in       => 'buy',
    charisma => 10,
    amount   => 910,
    type     => 'scroll',
);

is_deeply(\@p, [], "no hits is not an error");

@p = priceid (
    in       => 'base',
    charisma => 10,
    amount   => 910,
    type     => 'scroll',
);

is_deeply(\@p, [], "no hits is not an error");

@p = priceid (
    in       => 'sell',
    charisma => 10,
    amount   => 910,
    type     => 'scroll',
    out      => 'base',
);

is_deeply(\@p, [], "no hits is not an error");

