#!/usr/bin/perl

use Test::More (tests => 3);
use Test::NoWarnings;
use Test::Exception;

use Data::Chronicle::Writer;
use Data::Chronicle::Reader;
use Data::Chronicle::Mock;
use Quant::Framework::Utils::Test;
use Quant::Framework::EconomicEventCalendar;
use Date::Utility;

my ($chronicle_r, $chronicle_w) = Data::Chronicle::Mock::get_mocked_chronicle();

my $now = Date::Utility->new;
subtest sanity_check => sub {
    my $new_eco = Quant::Framework::EconomicEventCalendar->new({
            events => [{
                    symbol       => 'USD',
                    release_date => Date::Utility->new(time + 20000)->epoch,
                    source       => 'forexfactory',
                }
            ],
            recorded_date    => Date::Utility->new,
            chronicle_reader => $chronicle_r,
            chronicle_writer => $chronicle_w,
        });
    isa_ok($new_eco->recorded_date, 'Date::Utility');
    my $eco;
    my $dt = Date::Utility->new();
    lives_ok {

        $eco = Quant::Framework::Utils::Test::create_doc(
            'economic_events',
            {
                chronicle_reader => $chronicle_r,
                chronicle_writer => $chronicle_w,
                events           => [{
                        symbol       => 'USD',
                        release_date => $dt->epoch,
                        source       => 'forexfactory',
                        impact       => 3,
                        event_name   => 'FOMC',
                    }]
            },
        );
    }
    'lives if recorded_date is not specified';

    my $eco_event = $eco->events->[0];

    is($eco_event->{impact},       3,              'impact is loaded correctly');
    is($eco_event->{source},       'forexfactory', 'source is correct');
    is($eco_event->{event_name},   'FOMC',         'event_name loaded correctly');
    is($eco_event->{release_date}, $dt->epoch,     'release_date loaded correctly');
    is($eco_event->{symbol},       'USD',          'symbol loaded correctly');
};

subtest save_event_to_chronicle => sub {
    my $today        = Date::Utility->new;
    my $release_date = Date::Utility->new($today->epoch + 3600);

    my $calendar;

    lives_ok {
        $calendar = Quant::Framework::Utils::Test::create_doc(
            'economic_events',
            {
                recorded_date    => $today,
                chronicle_reader => $chronicle_r,
                chronicle_writer => $chronicle_w,
                events           => [{
                        symbol       => 'USD',
                        release_date => $release_date->epoch,
                        source       => 'forexfactory',
                        event_name   => 'my_test_name',
                    }]
            },
        );
    }
    'save didn\'t die';

    my $dm = Quant::Framework::EconomicEventCalendar->new({
        chronicle_reader => $chronicle_r,
        chronicle_writer => $chronicle_w
    });

    my @docs = $dm->get_latest_events_for_period({
        from => $release_date,
        to   => $release_date
    });
    ok scalar @docs > 0, 'document saved';

    #unit test for economic event should cover historical event.
    my $from = Date::Utility->new('2015-03-18');
    my $to   = Date::Utility->new('2016-03-24');

    my @hist_docs_case1 = $dm->get_latest_events_for_period({
        from => $from,
        to   => $to
    });
    ok scalar @hist_docs_case1 > 0, 'document saved';

    $from = Date::Utility->new('2015-02-18');
    $to   = Date::Utility->new('2016-02-27');

    my @hist_docs_case2 = $dm->get_latest_events_for_period({
        from => $from,
        to   => $to
    });
    ok scalar @hist_docs_case2 > 0, 'document saved';

    $from = Date::Utility->new('2015-01-05');
    $to   = Date::Utility->new('2016-01-27');

    my @hist_docs_case3 = $dm->get_latest_events_for_period({
        from => $from,
        to   => $to
    });
    ok scalar @hist_docs_case3 > 0, 'document saved';

};

1;
