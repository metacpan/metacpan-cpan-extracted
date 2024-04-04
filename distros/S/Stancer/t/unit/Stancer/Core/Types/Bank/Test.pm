package Stancer::Core::Types::Bank::Test;

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use English qw(-no_match_vars);
use Stancer::Core::Types::Bank::Stub;
use TestCase;

## no critic (RequireFinalReturn, ValuesAndExpressions::RequireInterpolationOfMetachars)

sub amount : Tests(7) {
    ok(Stancer::Core::Types::Bank::Stub->new(an_amount => random_integer(50, 99_999)), 'An amount');

    my $integer = random_integer(1, 49);
    my $string = random_string(10);
    my $message = 'Amount must be an integer and at least 50, %s given.';

    throws_ok {
        Stancer::Core::Types::Bank::Stub->new(an_amount => $integer);
    } 'Stancer::Exceptions::InvalidAmount', 'Must be at least 50';
    is($EVAL_ERROR->message, sprintf($message, q/"/ . $integer . q/"/), 'Message check');

    throws_ok {
        Stancer::Core::Types::Bank::Stub->new(an_amount => $string);
    } 'Stancer::Exceptions::InvalidAmount', 'Must be an integer';
    is($EVAL_ERROR->message, sprintf($message, q/"/ . $string . q/"/), 'Message check');

    throws_ok {
        Stancer::Core::Types::Bank::Stub->new(an_amount => undef);
    } 'Stancer::Exceptions::InvalidAmount', 'Can not be undef';
    is($EVAL_ERROR->message, sprintf($message, 'undef'), 'Message check');
}

sub bic : Tests(15) {
    for my $bic (bic_provider()) {
        ok(Stancer::Core::Types::Bank::Stub->new(a_bic => uc $bic), $bic . ' is valid');
    }

    my $bad = random_string(6);
    my $integer = random_integer(10);
    my $message = '%s is not a valid BIC code.';

    throws_ok {
        Stancer::Core::Types::Bank::Stub->new(a_bic => $bad);
    } 'Stancer::Exceptions::InvalidBic', $bad . ' is not valid';
    is($EVAL_ERROR->message, sprintf($message, q/"/ . $bad . q/"/), 'Message check');

    throws_ok {
        Stancer::Core::Types::Bank::Stub->new(a_bic => $integer);
    } 'Stancer::Exceptions::InvalidBic', 'Must be a string';
    is($EVAL_ERROR->message, sprintf($message, q/"/ . $integer . q/"/), 'Message check');

    throws_ok {
        Stancer::Core::Types::Bank::Stub->new(a_bic => undef);
    } 'Stancer::Exceptions::InvalidBic', 'Can not be undef';
    is($EVAL_ERROR->message, sprintf($message, 'undef'), 'Message check');
}

sub card_number : Tests(112) {
    my $string = random_string(10);
    my $message = '%s is not a valid credit card number.';

    for my $number (card_number_provider()) {
        my $bad = $number + 1;

        ok(Stancer::Core::Types::Bank::Stub->new(a_card_number => $number), $number . ' is valid');

        throws_ok {
            Stancer::Core::Types::Bank::Stub->new(a_card_number => $bad);
        } 'Stancer::Exceptions::InvalidCardNumber', $bad . ' is not valid';
        is($EVAL_ERROR->message, sprintf($message, q/"/ . $bad . q/"/), 'Message check');
    }

    throws_ok {
        Stancer::Core::Types::Bank::Stub->new(a_card_number => $string);
    } 'Stancer::Exceptions::InvalidCardNumber', 'Must be an integer';
    is($EVAL_ERROR->message, sprintf($message, q/"/ . $string . q/"/), 'Message check');

    throws_ok {
        Stancer::Core::Types::Bank::Stub->new(a_card_number => undef);
    } 'Stancer::Exceptions::InvalidCardNumber', 'Can not be undef';
    is($EVAL_ERROR->message, sprintf($message, 'undef'), 'Message check');
}

sub card_verification_code {
    my $message = '%s is not a valid card verification code.';
    my $cvc = random_integer(100, 999);
    my $string = random_string(10);

    ok(Stancer::Core::Types::Bank::Stub->new(a_card_verification_code => $cvc), $cvc . ' is valid');

    for my $len (1..5) {
        my $bad = random_integer(10) x $len;

        throws_ok {
            Stancer::Core::Types::Bank::Stub->new(a_card_verification_code => $bad);
        } 'Stancer::Exceptions::InvalidCardVerificationCode', $bad . ' is not valid';
        is($EVAL_ERROR->message, sprintf($message, q/"/ . $bad . q/"/), 'Message check');
    }

    throws_ok {
        Stancer::Core::Types::Bank::Stub->new(a_card_verification_code => $string);
    } 'Stancer::Exceptions::InvalidCardVerificationCode', 'Must be an integer';
    is($EVAL_ERROR->message, sprintf($message, q/"/ . $string . q/"/), 'Message check');

    throws_ok {
        Stancer::Core::Types::Bank::Stub->new(a_card_verification_code => undef);
    } 'Stancer::Exceptions::InvalidCardVerificationCode', 'Can not be undef';
    is($EVAL_ERROR->message, sprintf($message, 'undef'), 'Message check');
}

sub currency : Tests(28) {
    for my $currency (currencies_provider()) { # 11 currencies
        ok(Stancer::Core::Types::Bank::Stub->new(a_currency => lc $currency), lc($currency) . ' is valid');
        ok(Stancer::Core::Types::Bank::Stub->new(a_currency => uc $currency), uc($currency) . ' is valid');
    }

    my $integer = random_integer(999);
    my $string = random_string(3);
    my $message = 'Currency must be one of "aud", "cad", "chf", "dkk", "eur", "gbp", "jpy", "nok", "pln", "sek", "usd", %s given.';

    throws_ok {
        Stancer::Core::Types::Bank::Stub->new(a_currency => $integer);
    } 'Stancer::Exceptions::InvalidCurrency', 'Must a string';
    is($EVAL_ERROR->message, sprintf($message, q/"/ . $integer . q/"/), 'Message check');

    throws_ok {
        Stancer::Core::Types::Bank::Stub->new(a_currency => $string);
    } 'Stancer::Exceptions::InvalidCurrency', 'Must be one of expected currecies';
    is($EVAL_ERROR->message, sprintf($message, q/"/ . $string . q/"/), 'Message check');

    throws_ok {
        Stancer::Core::Types::Bank::Stub->new(a_currency => undef);
    } 'Stancer::Exceptions::InvalidCurrency', 'Can not be undef';
    is($EVAL_ERROR->message, sprintf($message, 'undef'), 'Message check');
}

sub iban : Tests(21) {
    for my $iban (iban_provider()) {
        ok(Stancer::Core::Types::Bank::Stub->new(an_iban => $iban), $iban . ' is valid');
    }

    my $bad = random_string(6);
    my $message = '%s is not a valid IBAN account.';

    throws_ok {
        Stancer::Core::Types::Bank::Stub->new(an_iban => $bad);
    } 'Stancer::Exceptions::InvalidIban', $bad . ' is not valid';
    is($EVAL_ERROR->message, sprintf($message, q/"/ . $bad . q/"/), 'Message check');

    throws_ok {
        Stancer::Core::Types::Bank::Stub->new(an_iban => undef);
    } 'Stancer::Exceptions::InvalidIban', 'Can not be undef';
    is($EVAL_ERROR->message, sprintf($message, 'undef'), 'Message check');
}

1;
