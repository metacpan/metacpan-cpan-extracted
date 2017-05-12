#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Date::Utility;

use Quant::Framework::StorageAccessor;
use Quant::Framework::CorporateAction;
use Quant::Framework::Utils::Test;
use Data::Chronicle::Writer;
use Data::Chronicle::Reader;
use Data::Chronicle::Mock;

my ($chronicle_r, $chronicle_w) = Data::Chronicle::Mock::get_mocked_chronicle;

my $storage_accessor = Quant::Framework::StorageAccessor->new(
    chronicle_reader => $chronicle_r,
    chronicle_writer => $chronicle_w,
);

is Quant::Framework::CorporateAction::load($storage_accessor, 'FPGZ'), undef, 'document is not present';

my $now = time;

my $old_date = Date::Utility->new->minus_time_interval("15m");

subtest "load/save" => sub {
    my $ca = Quant::Framework::CorporateAction::create($storage_accessor, 'QWER', $old_date);
    ok $ca, "empty corporate actions object has been created";

    my $ca2 = $ca->update({
            "62799500" => {
                "monitor_date"   => "2014-02-07T06:00:07Z",
                "type"           => "ACQUIS",
                "monitor"        => 1,
                "description"    => "Acquisition",
                "effective_date" => "15-Jul-14",
                "flag"           => "N"
            },
        },
        $old_date
    );

    ok $ca2, "updated corporate actions object";
    $ca2->save;

    my $ca3 = Quant::Framework::CorporateAction::load($storage_accessor, 'QWER');
    ok $ca3;
    is $ca3->actions->{62799500}->{type},           "ACQUIS";
    is $ca3->actions->{62799500}->{effective_date}, "15-Jul-14";

    $ca3 = $ca2->update({
            "32799500" => {
                "monitor_date"   => "2015-02-07T06:00:07Z",
                "type"           => "DIV",
                "monitor"        => 1,
                "description"    => "Divided Stocks",
                "effective_date" => "15-Jul-15",
                "flag"           => "N"
            },
        },
        $old_date->plus_time_interval("5m"));
    $ca3->save;

    my $ca4 = Quant::Framework::CorporateAction::load($storage_accessor, 'QWER');
    is $ca4->actions->{62799500}->{type}, "ACQUIS";
    is $ca4->actions->{32799500}->{type}, "DIV";

    my $ca5 = Quant::Framework::CorporateAction::load($storage_accessor, 'QWER', $old_date);
    ok $ca5, "load via specifying exact date";
    is scalar(keys %{$ca5->actions}), 1, "old document contains 1 action";
};

subtest 'save new corporate actions' => sub {
    my $now = Date::Utility->new;
    my $corp = Quant::Framework::CorporateAction::create($storage_accessor, 'USAAPL', $now);

    is_deeply $corp->actions, {}, "by default it is empty";

    my $new_actions = {
        1122334 => {
            effective_date => $now->datetime_iso8601,
            modifier       => 'multiplication',
            value          => 1.456,
            description    => 'Test data 2',
            flag           => 'N'
        }};

    my $new_corp = $corp->update($new_actions, $now->plus_time_interval("1m"));
    $new_corp->save;

    my $after_save_corp = Quant::Framework::CorporateAction::load($storage_accessor, 'USAAPL');
    ok $after_save_corp;
    is $after_save_corp->document->recorded_date, $now->plus_time_interval("1m");
    is keys(%{$after_save_corp->actions}), 1, "has one action";

    subtest "no duplicates" => sub {
        $new_corp->update({
                1122334 => {
                    effective_date => $now->datetime_iso8601,
                    modifier       => 'multiplication',
                    value          => 1.456,
                    description    => 'Duplicate action',
                    flag           => 'N'
                }
            },
            $now->plus_time_interval("2m"))->save;
        my $persisted_actions = Quant::Framework::CorporateAction::load($storage_accessor, 'USAAPL')->actions;
        isnt $persisted_actions->{1122334}->{description}, 'Duplicate action';
        is $persisted_actions->{1122334}->{description},   'Test data 2';
    };

    subtest 'update existing corporate actions' => sub {
        $new_corp->update({
                1122334 => {
                    effective_date => $now->datetime_iso8601,
                    modifier       => 'multiplication',
                    value          => 1.987,
                    description    => 'Update to existing actions',
                    flag           => 'U'
                }
            },
            $now->plus_time_interval("3m"))->save;
        my $persisted_actions = Quant::Framework::CorporateAction::load($storage_accessor, 'USAAPL')->actions;
        is $persisted_actions->{1122334}->{description}, 'Update to existing actions';
        is $persisted_actions->{1122334}->{value}, 1.987, 'value is also updated';
    };

    subtest 'cancel existing corporate actions' => sub {
        $new_corp->update({
                1122334 => {
                    effective_date => $now->datetime_iso8601,
                    modifier       => 'multiplication',
                    value          => 1.987,
                    description    => 'Update to existing actions',
                    flag           => 'D'
                }
            },
            $now->plus_time_interval("4m"))->save;
        my $persisted_actions = Quant::Framework::CorporateAction::load($storage_accessor, 'USAAPL')->actions;
        is_deeply $persisted_actions, {}, 'action deleted from db';
    };

    subtest 'save critical actions' => sub {
        my $action_id = 11223346;
        $new_corp->update({
                $action_id => {
                    effective_date  => $now->datetime_iso8601,
                    suspend_trading => 1,
                    disabled_date   => $now->datetime_iso8601,
                    description     => 'Save critical action',
                    flag            => 'N'
                }
            },
            $now->plus_time_interval("5m"))->save;
        my $persisted_actions = Quant::Framework::CorporateAction::load($storage_accessor, 'USAAPL')->actions;
        ok $persisted_actions->{$action_id}, 'critical action saved on db';
        is $persisted_actions->{$action_id}->{suspend_trading}, 1, 'suspend_trading';
    };
};

done_testing;
