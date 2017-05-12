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

my ($chronicle_r, $chronicle_w) = Data::Chronicle::Mock::get_mocked_chronicle();

subtest 'save interest rate' => sub {
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
            rates            => {365 => 0},
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
        'successfully retrieved saved document from database';
    }
    'successfully save interest rates for USD';
};
