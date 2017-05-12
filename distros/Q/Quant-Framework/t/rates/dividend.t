#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;
use Test::Exception;
use Test::NoWarnings;

use Quant::Framework::Utils::Test;
use Quant::Framework::Asset;
use Data::Chronicle::Writer;
use Data::Chronicle::Reader;
use Data::Chronicle::Mock;
use Date::Utility;

my ($chronicle_r, $chronicle_w) = Data::Chronicle::Mock::get_mocked_chronicle();

subtest 'save dividend' => sub {
    lives_ok {
        is(
            Quant::Framework::Asset->new(
                symbol           => 'AEX',
                chronicle_reader => $chronicle_r,
                chronicle_writer => $chronicle_w
                )->document,
            undef,
            'document is not present'
        );

        my $dvd = Quant::Framework::Asset->new(
            rates            => {365          => 0.1},
            discrete_points  => {'2014-10-10' => 0},
            recorded_date    => Date::Utility->new('2014-10-10'),
            symbol           => 'AEX',
            chronicle_reader => $chronicle_r,
            chronicle_writer => $chronicle_w
        );
        ok $dvd->save, 'save without error';
        lives_ok {
            Quant::Framework::Asset->new(
                symbol           => 'AEX',
                chronicle_reader => $chronicle_r,
                chronicle_writer => $chronicle_w
                )->document
        }
        'successfully retrieved saved document from chronicle';

        my $dv = Quant::Framework::Asset->new(
            symbol           => 'AEX',
            chronicle_reader => $chronicle_r,
            chronicle_writer => $chronicle_w
        )->document;

        is $dv->{symbol}, "AEX", "symbol is retrieved correctly";
        is $dv->{discrete_points}->{'2014-10-10'}, 0,   "points retrieved correctly";
        is $dv->{rates}->{365},                    0.1, "rates retrieved correctly";
    }
    'sucessfully save dividend for AEX';
};
