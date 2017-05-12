#!/usr/bin/perl

use strict;
use warnings;

use Quant::Framework::Utils::Test;
use Test::More tests => 4;
use Test::NoWarnings;
use Test::Exception;

use Quant::Framework::Holiday;
use Data::Chronicle::Mock;
use Date::Utility;

my $now = Date::Utility->new;

my ($chronicle_r, $chronicle_w) = Data::Chronicle::Mock::get_mocked_chronicle();

subtest 'error check' => sub {
    throws_ok { Quant::Framework::Holiday->new(recorded_date => $now) } qr/required/, 'throws error if not enough argument to create a holiday';
    throws_ok { Quant::Framework::Holiday->new(calendar => {}) } qr/required/, 'throws error if not enough argument to create a holiday';
    lives_ok { Quant::Framework::Holiday->new(recorded_date => $now, calendar => {}) } 'creates a holiday object if all args are present';
};

subtest 'save and retrieve event' => sub {
    lives_ok {
        my $h = Quant::Framework::Holiday->new(
            recorded_date    => $now,
            chronicle_reader => $chronicle_r,
            chronicle_writer => $chronicle_w,
            calendar         => {
                $now->epoch => {
                    'Test Event' => ['USD'],
                }
            },
        );
        ok $h->save, 'succesfully saved event.';
        $h = Quant::Framework::Holiday->new(
            recorded_date    => $now,
            chronicle_reader => $chronicle_r,
            chronicle_writer => $chronicle_w,
            calendar         => {
                $now->epoch => {
                    'Test Event 2' => ['EURONEXT'],
                }
            },
        );
        ok $h->save, 'sucessfully saved event 2.';
        my $event = Quant::Framework::Holiday::get_holidays_for($chronicle_r, 'EURONEXT');
        ok $event->{$now->truncate_to_day->epoch}, 'has a holiday';
        is $event->{$now->truncate_to_day->epoch}, 'Test Event 2', 'Found saved holiday';
    }
    'saves event';
    my $next_day = $now->plus_time_interval('1d');
    lives_ok {
        my $h = Quant::Framework::Holiday->new(
            recorded_date    => $next_day,
            chronicle_reader => $chronicle_r,
            chronicle_writer => $chronicle_w,
            calendar         => {
                $next_day->epoch => {
                    'Test Event Update' => ['AUD'],
                }
            },
        );
        ok $h->save, 'successfully saved event update';
        my $event = Quant::Framework::Holiday::get_holidays_for($chronicle_r, 'USD');
        ok !$event->{$next_day->truncate_to_day->epoch}, 'no holiday';
        $event = Quant::Framework::Holiday::get_holidays_for($chronicle_r, 'AUD');
        ok $event->{$next_day->truncate_to_day->epoch}, 'has a holiday';
        is $event->{$next_day->truncate_to_day->epoch}, 'Test Event Update', 'Found saved holiday';
    }
    'removed historical holiday when new event is inserted';
};

subtest 'save and retrieve event in history' => sub {
    my $yesterday = $now->minus_time_interval('1d');
    Quant::Framework::Utils::Test::create_doc(
        'holiday',
        {
            recorded_date    => $yesterday,
            chronicle_reader => $chronicle_r,
            chronicle_writer => $chronicle_w,
            calendar         => {$now->epoch => {'Test Historical Save' => ['EURONEXT']}}});

    my $h = Quant::Framework::Holiday::get_holidays_for($chronicle_r, 'EURONEXT', $yesterday);
    ok $h->{$now->truncate_to_day->epoch}, 'has a holiday';
    is $h->{$now->truncate_to_day->epoch}, 'Test Historical Save', 'Found saved holiday';
    $h = Quant::Framework::Holiday::get_holidays_for($chronicle_r, 'EURONEXT', $yesterday->minus_time_interval('1d'));
    ok !$h->{$now->truncate_to_day->epoch}, 'no holiday';
};
