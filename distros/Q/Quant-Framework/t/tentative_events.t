#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;
use Test::NoWarnings;
use Test::Exception;

use Date::Utility;
use Data::Chronicle::Writer;
use Data::Chronicle::Reader;
use Data::Chronicle::Mock;
use Quant::Framework::EconomicEventCalendar;
use Quant::Framework::Utils::Test;

my ($chronicle_r, $chronicle_w) = Data::Chronicle::Mock::get_mocked_chronicle();

my $tentative = {
    'estimated_release_date' => time,
    'event_name'             => 'Trade Balance',
    'id'                     => 'f4b74431c78eab54',
    'impact'                 => 5,
    'is_tentative'           => 1,
    'recorded_date'          => 1457338907,
    'source'                 => 'forexfactory',
    'symbol'                 => 'CNY',
};
my $regular = {
    'event_name'    => 'HIA New Home Sales m/m',
    'id'            => '31f05851b6d3b902',
    'impact'        => 1,
    'recorded_date' => 1457338907,
    'release_date'  => 1456876800,
    'source'        => 'forexfactory',
    'symbol'        => 'AUD',
};

subtest 'saving tentative events' => sub {
    lives_ok {
        my $eco = Quant::Framework::EconomicEventCalendar->new(
            events           => [$tentative, $regular],
            recorded_date    => Date::Utility->new,
            chronicle_reader => $chronicle_r,
            chronicle_writer => $chronicle_w,
        );
        ok $eco->save, 'saves economic events';
        lives_ok {
            my $ref = $chronicle_r->get('economic_events', 'economic_events');
            is scalar(@{$ref->{events}}), 1, 'one event retrieved';
            is $ref->{events}->[0]->{event_name}, $regular->{event_name}, 'saved the correct event';
        }
        'regular event';
        lives_ok {
            my $ref = $chronicle_r->get('economic_events', 'economic_events_tentative');
            is scalar(keys %$ref), 1, 'one tentative event retrieved';
            ok $ref->{$tentative->{id}}, 'saved the correct tentative event';
        }
        'tentative event';
    }
    'saving regular and tentative events';
};

my %new_tentative = %$tentative;
subtest 'update tentative events' => sub {
    my $blackout     = 1456876900 - 3600;
    my $blackout_end = 1456876900 + 3600;
    $new_tentative{blankout}     = $blackout;
    $new_tentative{blankout_end} = $blackout_end;

    lives_ok {
        my $eco = Quant::Framework::EconomicEventCalendar->new(
            recorded_date    => Date::Utility->new,
            chronicle_reader => $chronicle_r,
            chronicle_writer => $chronicle_w,
        );
        ok $eco->update(\%new_tentative);
        lives_ok {
            my $ref = $chronicle_r->get('economic_events', 'economic_events');
            is scalar(@{$ref->{events}}), 2, 'two event retrieved';
            is $ref->{events}->[0]->{event_name}, $regular->{event_name}, 'saved the correct event';
            is $ref->{events}->[1]->{event_name}, $new_tentative{event_name}, 'saved the correct event';
            is $ref->{events}->[1]->{release_date}, ($blackout + $blackout_end) / 2, 'correct release date saved';
        }
        'regular event';
        lives_ok {
            my $ref = $chronicle_r->get('economic_events', 'economic_events_tentative');
            is scalar(keys %$ref), 1, 'one tentative event retrieved';
            ok $ref->{$new_tentative{id}}, 'saved the correct tentative event';
            ok $ref->{$new_tentative{id}}->{release_date}, 'has release date';
            ok $ref->{$new_tentative{id}}->{blankout},     'has blankout';
            ok $ref->{$new_tentative{id}}->{blankout_end}, 'has blankout_end';
        }
        'tentative event';
    }
    'updating tentative event';
    lives_ok {
        $new_tentative{blankout}     = $blackout - 1;
        $new_tentative{blankout_end} = $blackout_end + 1;
        my $eco = Quant::Framework::EconomicEventCalendar->new(
            recorded_date    => Date::Utility->new,
            chronicle_reader => $chronicle_r,
            chronicle_writer => $chronicle_w,
        );
        ok $eco->update(\%new_tentative);
        my $ref = $chronicle_r->get('economic_events', 'economic_events');
        is scalar(@{$ref->{events}}), 2, 'number of events is still two';
        my $te = (grep { $_->{id} eq $new_tentative{id} } @{$ref->{events}})[0];
        is $te->{blankout},     $new_tentative{blankout},     'updated blankout';
        is $te->{blankout_end}, $new_tentative{blankout_end}, 'updated blankout_end';
    }
    'update again with different blockout time';
};

subtest 'retry with same events' => sub {
    lives_ok {
        my $eco = Quant::Framework::EconomicEventCalendar->new(
            events           => [\%new_tentative, $regular],
            recorded_date    => Date::Utility->new,
            chronicle_reader => $chronicle_r,
            chronicle_writer => $chronicle_w,
        );
        ok $eco->save, 'saves economic events';
        lives_ok {
            my $ref = $chronicle_r->get('economic_events', 'economic_events');
            is scalar(@{$ref->{events}}), 2, 'one event retrieved';
            is $ref->{events}->[0]->{event_name}, $regular->{event_name}, 'saved the correct event';
            is $ref->{events}->[1]->{event_name}, $new_tentative{event_name}, 'saved the correct event';
            ok $ref->{events}->[1]->{release_date};
        }
        'regular event';
        lives_ok {
            my $ref = $chronicle_r->get('economic_events', 'economic_events_tentative');
            is scalar(keys %$ref), 1, 'one tentative event retrieved';
            ok $ref->{$new_tentative{id}}, 'saved the correct tentative event';
            ok $ref->{$new_tentative{id}}->{release_date}, 'has release date';
            ok $ref->{$new_tentative{id}}->{blankout},     'has blankout';
            ok $ref->{$new_tentative{id}}->{blankout_end}, 'has blankout_end';
        }
        'tentative event';
    }
    'retry saving regular and tentative events';
};

subtest 'tentative event happened' => sub {
    my $now      = time;
    my %happened = %{$tentative};
    delete $happened{is_tentative};
    $happened{release_date} = $now;
    lives_ok {
        my $eco = Quant::Framework::EconomicEventCalendar->new(
            events           => [\%happened, $regular],
            recorded_date    => Date::Utility->new,
            chronicle_reader => $chronicle_r,
            chronicle_writer => $chronicle_w,
        );
        ok $eco->save, 'saves economic events';
        lives_ok {
            my $ref = $chronicle_r->get('economic_events', 'economic_events');
            is scalar(@{$ref->{events}}), 2, 'one event retrieved';
            my $updated_tentative = (grep { $_->{id} eq $happened{id} } @{$ref->{events}})[0];
            is $updated_tentative->{actual_release_date}, $now, 'updated actual_release_date';
            is $updated_tentative->{estimated_release_date}, $happened{estimated_release_date}, 'estimated_release_date unchanged';
            is $updated_tentative->{release_date}, $now, 'updated release_date';
            ok !$updated_tentative->{blankout};
            ok !$updated_tentative->{blankout_end};
            ok !$updated_tentative->{is_tentative};
        }
        'regular event';
    }
};
