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
use Quant::Framework::ImpliedRate;
use Date::Utility;

my ($chronicle_r, $chronicle_w) = Data::Chronicle::Mock::get_mocked_chronicle();

subtest 'save implied rate' => sub {
    lives_ok {
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
            rates            => {365 => 0},
            recorded_date    => Date::Utility->new('2014-10-10'),
            type             => 'implied',
            chronicle_reader => $chronicle_r,
            chronicle_writer => $chronicle_w,
        );
        ok $imp->save, 'save successfully';
        lives_ok {
            my $new = Quant::Framework::ImpliedRate->new(
                symbol           => 'USD-JPY',
                chronicle_reader => $chronicle_r,
                chronicle_writer => $chronicle_w,
            );
            ok $new->document;
            is $new->type, 'implied';
        }
        'retrieved saved document';
    }
    'successfully save implied rate';
};
