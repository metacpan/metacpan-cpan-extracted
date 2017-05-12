#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;
use Test::Exception;
use Test::NoWarnings;

use Data::Chronicle::Writer;
use Data::Chronicle::Reader;
use Data::Chronicle::Mock;
use Quant::Framework::Utils::Test;
use Quant::Framework::InterestRate;
use Quant::Framework::ImpliedRate;
use Quant::Framework::Currency;

my ($chronicle_r, $chronicle_w) = Data::Chronicle::Mock::get_mocked_chronicle();

subtest 'retrieve interest rate and implied rate' => sub {
    is(
        Quant::Framework::InterestRate->new(
            symbol           => 'USD',
            chronicle_reader => $chronicle_r,
            chronicle_writer => $chronicle_w,
            )->document,
        undef,
        'document is not present'
    );

    lives_ok {
        my $int = Quant::Framework::InterestRate->new(
            symbol           => 'USD',
            rates            => {365 => 0.3},
            recorded_date    => Date::Utility->new('2014-10-10'),
            chronicle_reader => $chronicle_r,
            chronicle_writer => $chronicle_w,
        );
        ok $int->save, 'save without error';
        lives_ok {
            my $new = Quant::Framework::InterestRate->new(
                symbol           => 'USD',
                chronicle_reader => $chronicle_r,
                chronicle_writer => $chronicle_w
            );

            ok $new->document;
            is $new->type, 'market';
        }
        'successfully retrieved interest rates and implied rates';

        is(
            Quant::Framework::ImpliedRate->new(
                symbol           => 'USD-JPY',
                chronicle_reader => $chronicle_r,
                chronicle_writer => $chronicle_w,
                )->document,
            undef,
            'document is not present'
        );
        my $imp = Quant::Framework::ImpliedRate->new(
            symbol           => 'USD-JPY',
            rates            => {365 => 0.1},
            recorded_date    => Date::Utility->new('2014-10-10'),
            type             => 'implied',
            chronicle_reader => $chronicle_r,
            chronicle_writer => $chronicle_w,
        );
        ok $imp->save, 'save implied rates successfully';

        my $usd = Quant::Framework::Currency->new({
            symbol           => 'USD',
            for_date         => Date::Utility->new('2014-10-10'),
            chronicle_reader => $chronicle_r,
            chronicle_writer => $chronicle_w,
        });

        my $tiy   = 365.0 / 365.0;
        my $rates = $usd->rate_for($tiy);

        my $implied_rates = $usd->rate_implied_from('JPY', $tiy);

        is $rates,         0.003, "rates retrieved successfully through Currency.pm";
        is $implied_rates, 0.001, "implied rates retrieved successfully through Currency.pm";
    }
    'successfully retrieve interest rates and implied rates for USD';
};
