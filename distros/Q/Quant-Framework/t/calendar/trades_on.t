#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;
use Test::NoWarnings;

use Quant::Framework::Utils::Test;
use Quant::Framework::TradingCalendar;
use Test::MockModule;
use File::ShareDir ();
use YAML::XS qw(LoadFile);

my ($chronicle_r, $chronicle_w) = Data::Chronicle::Mock::get_mocked_chronicle();
my $date = Date::Utility->new('2013-12-08');
note("Exchange tests for_date " . $date->date);

subtest 'trading days' => sub {
    my $exp       = LoadFile(File::ShareDir::dist_file('Quant-Framework', 'expected_trading_days.yml'));
    my @exchanges = qw(JSC SES NYSE_SPC ASX ODLS ISE BSE FOREX METAL JSE SWX FSE DFM EURONEXT HKSE NYSE RANDOM RANDOM_NOCTURNE TSE OSLO);

    foreach my $exchange_symbol (@exchanges) {
        my $e = Quant::Framework::TradingCalendar->new({
            symbol           => $exchange_symbol,
            chronicle_reader => $chronicle_r
        });
        for (0 .. 6) {
            is $e->trades_on($date->plus_time_interval($_ . 'd')), $exp->{$exchange_symbol}->[$_],
                'correct trading days list for ' . $exchange_symbol;
        }
    }
};

Quant::Framework::Utils::Test::create_doc(
    'holiday',
    {
        recorded_date => $date,
        calendar      => {
            "25-Dec-2013" => {
                "Christmas Day" => [qw(FOREX METAL)],
            },
            "1-Jan-2014" => {
                "New Year's Day" => [qw(FOREX METAL)],
            },
        },
        chronicle_reader => $chronicle_r,
        chronicle_writer => $chronicle_w,
    });

subtest 'trades on holidays/pseudo-holidays' => sub {
    my @expected = qw(1 1 1 0 0 1 1 0 1 1 0 0 1 1 0);
    my $mocked   = Test::MockModule->new('Quant::Framework::TradingCalendar');
    $mocked->mock('_object_expired', sub { 1 });
    my $forex = Quant::Framework::TradingCalendar->new({
        symbol           => 'FOREX',
        chronicle_reader => $chronicle_r,
        for_date         => $date
    });
    my $counter = 0;
    foreach my $days (sort { $a <=> $b } keys %{$forex->pseudo_holidays}) {
        my $date = Date::Utility->new(0)->plus_time_interval($days . 'd');
        is $forex->trades_on($date), $expected[$counter];
        $counter++;
    }

    my $metal = Quant::Framework::TradingCalendar->new({
        symbol           => 'METAL',
        chronicle_reader => $chronicle_r,
        locale           => 'EN',
        for_date         => $date
    });
 
    $counter = 0;
    foreach my $days (sort { $a <=> $b } keys %{$metal->pseudo_holidays}) {
        my $date = Date::Utility->new(0)->plus_time_interval($days . 'd');
        is $metal->trades_on($date), $expected[$counter];
        $counter++;
    }

};
