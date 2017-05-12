#!/usr/bin/perl

use strict;
use warnings;

use Quant::Framework::Utils::Test;
use Test::More tests => 4;
use Test::NoWarnings;
use Test::Exception;

use Quant::Framework::PartialTrading;
use Date::Utility;

my $now = Date::Utility->new;

my ($chronicle_r, $chronicle_w) = Data::Chronicle::Mock::get_mocked_chronicle();

subtest 'error check' => sub {
    throws_ok { Quant::Framework::PartialTrading->new(recorded_date => $now)->save } qr/required/,
        'throws error if not enough argument to create a early close calendar';
    throws_ok { Quant::Framework::PartialTrading->new(calendar => {})->save } qr/required/,
        'throws error if not enough argument to create a early close calendar';
    lives_ok {
        Quant::Framework::PartialTrading->new(
            type             => 'early_closes',
            recorded_date    => $now,
            calendar         => {},
            chronicle_reader => $chronicle_r,
            chronicle_writer => $chronicle_w,
            )->save
    }
    'creates a early close object if all args are present';
    throws_ok { Quant::Framework::PartialTrading->new(type => 'some_data', recorded_date => $now, calendar => {})->save }
    qr/Invalid partial-trading type/,
        'throws error if partial trading type is invalid';
};

subtest 'save and retrieve early close dates' => sub {
    lives_ok {
        my $ec = Quant::Framework::PartialTrading->new(
            type          => 'early_closes',
            recorded_date => $now,
            calendar      => {
                $now->epoch => {
                    "18:00" => ['FOREX', 'METAL'],
                },
            },
            chronicle_reader => $chronicle_r,
            chronicle_writer => $chronicle_w,
        );
        ok $ec->save, 'successfully save early close calendar';
        $ec = Quant::Framework::PartialTrading->new(
            type          => 'early_closes',
            recorded_date => $now,
            calendar      => {
                $now->epoch => {
                    "18:00" => ['ASX'],
                },
                $now->plus_time_interval('2d')->epoch => {
                    "21:00" => ['ASX'],
                },
            },
            chronicle_reader => $chronicle_r,
            chronicle_writer => $chronicle_w,
        );
        ok $ec->save, 'save second early close calendar';
    }
    'save early close calendar';
    lives_ok {
        my $early_closes = Quant::Framework::PartialTrading->new({
                chronicle_reader => $chronicle_r,
                chronicle_writer => $chronicle_w,
                type             => 'early_closes',
            })->get_partial_trading_for('FOREX');
        is scalar(keys %$early_closes), 1, 'retrieved one early close date for FOREX';
        is $early_closes->{$now->truncate_to_day->epoch}, "18:00", 'correct early close time for FOREX';


        my $early_closes_metal = Quant::Framework::PartialTrading->new({
                chronicle_reader => $chronicle_r,
                chronicle_writer => $chronicle_w,
                type             => 'early_closes',
            })->get_partial_trading_for('METAL');
        is scalar(keys %$early_closes_metal), 1, 'retrieved one early close date for METAL';
        is $early_closes_metal->{$now->truncate_to_day->epoch}, "18:00", 'correct early close time for METAL';



        $early_closes = Quant::Framework::PartialTrading->new({
                chronicle_reader => $chronicle_r,
                chronicle_writer => $chronicle_w,
                type             => 'early_closes',
            })->get_partial_trading_for('ASX');
        is scalar(keys %$early_closes), 2, 'retrieved one early close date for ASX';
        is $early_closes->{$now->truncate_to_day->epoch}, "18:00", 'correct early close time';
        is $early_closes->{$now->plus_time_interval('2d')->truncate_to_day->epoch}, "21:00", 'correct early close time';
    }
    'retrieve early close calendar';
};

subtest 'save and retrieve early closes in history' => sub {
    my $yesterday = $now->minus_time_interval('1d');
    Quant::Framework::Utils::Test::create_doc(
        'partial_trading',
        {
            chronicle_reader => $chronicle_r,
            chronicle_writer => $chronicle_w,
            type             => 'early_closes',
            recorded_date    => $yesterday,
            calendar         => {$now->epoch => {'18:00' => ['EURONEXT']}}});

    my $h = Quant::Framework::PartialTrading->new({
            chronicle_reader => $chronicle_r,
            chronicle_writer => $chronicle_w,
            type             => 'early_closes',
        })->get_partial_trading_for('EURONEXT', $yesterday);
    ok $h->{$now->truncate_to_day->epoch}, '18:00';

    $h = Quant::Framework::PartialTrading->new({
            chronicle_reader => $chronicle_r,
            chronicle_writer => $chronicle_w,
            type             => 'early_closes',
        })->get_partial_trading_for('EURONEXT', $yesterday->minus_time_interval('1d'));
    ok !$h->{$now->truncate_to_day->epoch}, 'no early close dates';
};
