#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;
use Test::NoWarnings;

use Quant::Framework::TradingCalendar;
use Date::Utility;
use Quant::Framework::Utils::Builder;
use Quant::Framework::Utils::Test;

my ($chronicle_r, $chronicle_w) = Data::Chronicle::Mock::get_mocked_chronicle();

my $date = Date::Utility->new('2013-12-01');
note("Exchange tests for_date " . $date->date);
Quant::Framework::Utils::Test::create_doc(
    'holiday',
    {
        recorded_date => $date,
        calendar      => {
            "25-Dec-2013" => {
                "Christmas Day" => [qw(FOREX METAL)],
            },
            "29-Mar-2013" => {
                "Good Friday" => ['USD'],
            },
        },
        chronicle_reader => $chronicle_r,
        chronicle_writer => $chronicle_w,
    });

subtest 'weight on' => sub {
    my $chritmas      = Date::Utility->new('2013-12-25');
    my $good_friday   = Date::Utility->new('2013-03-29');
    my $usdjpy_config = Quant::Framework::Utils::Test::create_underlying_config('frxUSDJPY');
    my $fx_builder    = Quant::Framework::Utils::Builder->new({
        chronicle_reader  => $chronicle_r,
        chronicle_writer  => $chronicle_w,
        underlying_config => $usdjpy_config,
        for_date          => $date,
    });
    my $forex = $fx_builder->build_trading_calendar;

    my $xauusd_config = Quant::Framework::Utils::Test::create_underlying_config('frxXAUUSD');
    my $metal_builder = Quant::Framework::Utils::Builder->new({
        chronicle_reader  => $chronicle_r,
        chronicle_writer  => $chronicle_w,
        underlying_config => $xauusd_config,
        for_date          => $date
    });
    my $metal = $metal_builder->build_trading_calendar;

    ok $forex->has_holiday_on($chritmas), 'USDJPY has holiday on ' . $chritmas->date;
    is $forex->simple_weight_on($date),   0, 'USDJPY weight is zero on a holiday';
    ok $metal->has_holiday_on($chritmas), 'XAUUSD has holiday on ' . $chritmas->date;
    is $metal->simple_weight_on($date),   0, 'XAUUSD weight is zero on a holiday';
    my $weekend = Date::Utility->new('2013-12-8');
    note($weekend->date . ' is a weekend');
    is $forex->simple_weight_on($weekend), 0, 'USDJPY weight is zero on weekend';
    is $metal->simple_weight_on($weekend), 0, 'XAUUSD weight is zero on weekend';
    my $pseudo_holiday_date = Date::Utility->new('2013-12-24');
    note($pseudo_holiday_date->date . ' is a pseudo holiday');
    is $forex->simple_weight_on($pseudo_holiday_date), 0.5, '0.5 for pseudo holiday';
    is $metal->simple_weight_on($pseudo_holiday_date), 0.5, '0.5 for pseudo holiday';
    my $trading_date = Date::Utility->new('2013-12-2');
    is $forex->simple_weight_on($trading_date), 1,   'USDJPY weight is 1 on a trading day';
    is $metal->simple_weight_on($trading_date), 1,   'XAUUSD weight is 1 on a trading day';
    is $forex->weight_on($good_friday),         0.5, 'USDJPY weight is 0.5 on good friday ';
    is $metal->weight_on($good_friday),         0.5, 'XAUUSD weight is 0.5 on good friday';

};
