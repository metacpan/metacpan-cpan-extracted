package Stancer::Role::Amount::Write::Test;

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use English qw(-no_match_vars);
use Stancer::Role::Amount::Write::Stub;
use TestCase;

## no critic (RequireExtendedFormatting, RequireFinalReturn)

sub amount : Tests(5) {
    my $object = Stancer::Role::Amount::Write::Stub->new();
    my $amount = random_integer(50, 9999);

    is($object->amount, undef, 'Undefined by default');

    $object->amount($amount);

    is($object->amount, $amount, 'Should be updated');
    cmp_deeply_json($object, { amount => $amount }, 'Should be exported');

    throws_ok {
        $object->amount(random_integer(0, 49))
    } 'Stancer::Exceptions::InvalidAmount', 'Throw an exception if not ok';
    like($EVAL_ERROR->message, qr/must be an integer and at least 50/sm, 'Exception should have a message');
}

sub currency : Tests(12) {
    my $object = Stancer::Role::Amount::Write::Stub->new();

    is($object->currency, undef, 'Undefined by default');

    foreach my $currency (qw(eur gbp usd)) {
        $object->currency($currency);

        is($object->currency, $currency, 'Should update currency');
        cmp_deeply_json($object, { currency => $currency }, 'Should be exported');

        $object->currency(uc $currency);

        is($object->currency, $currency, 'Should allow uppercase currency and modify case on it');
    }

    throws_ok {
        $object->currency(random_string(3))
    } 'Stancer::Exceptions::InvalidCurrency', 'Throw an exception if not ok';

    ## no critic (RegularExpressions::ProhibitComplexRegexes)
    like(
        $EVAL_ERROR->message,
        qr/Currency must be one of "aud", "cad", "chf", "dkk", "eur", "gbp", "jpy", "nok", "pln", "sek", "usd"/sm,
        'Exception should have a message',
    );
    ## use critic
}

1;
