#!/usr/bin/env perl

#########################

use strict;
use Test::More;
use Data::Dumper;

# checks against localtime will fail otherwise
use POSIX qw(tzset);
$ENV{'TZ'} = "CET";
POSIX::tzset();

BEGIN {
    if( $^O eq 'MSWin32' ) {
        plan skip_all => 'windows is not supported';
    }
    else {
        plan tests => 4;
    }

    require 't/00_test_utils.pm';
    import TestUtils;
}

use_ok('Monitoring::Availability');

#########################
# read logs from data
my $logs;
while(my $line = <DATA>) {
    $logs .= $line;
}

my $expected = {
    'services' => {},
    'hosts' => {
        'mo' => {
            'time_up'          => 172218,
            'time_down'        => 582,
            'time_unreachable' => 0,

            'scheduled_time_up'             => 0,
            'scheduled_time_down'           => 0,
            'scheduled_time_unreachable'    => 0,
            'scheduled_time_indeterminate'  => 0,

            'time_indeterminate_nodata'     => 0,
            'time_indeterminate_notrunning' => 0,
            'time_indeterminate_outside_timeperiod' => 0,
            'breakdown' => {
                                '2012-04-22' => {
                                                  'time_down' => 582,
                                                  'time_indeterminate_notrunning' => 0,
                                                  'scheduled_time_down' => 0,
                                                  'scheduled_time_up' => 0,
                                                  'time_unreachable' => 0,
                                                  'time_indeterminate_nodata' => 0,
                                                  'time_up' => 85818,
                                                  'scheduled_time_unreachable' => 0,
                                                  'time_indeterminate_outside_timeperiod' => 0,
                                                  'scheduled_time_indeterminate' => 0,
                                                  'timestamp' => 1335045600
                                                },
                                '2012-04-21' => {
                                                  'time_down' => 0,
                                                  'time_indeterminate_notrunning' => 0,
                                                  'scheduled_time_down' => 0,
                                                  'scheduled_time_up' => 0,
                                                  'time_unreachable' => 0,
                                                  'time_indeterminate_nodata' => 0,
                                                  'time_up' => 86400,
                                                  'scheduled_time_unreachable' => 0,
                                                  'time_indeterminate_outside_timeperiod' => 0,
                                                  'scheduled_time_indeterminate' => 0,
                                                  'timestamp' => 1334959200
                                                }
                              },
        }
    }
};

#########################
my $ma = Monitoring::Availability->new(
    'verbose'                       => 0,
    'backtrack'                     => 4,
    'assumestateretention'          => 'yes',
    'assumeinitialstates'           => 'yes',
    'assumestatesduringnotrunning'  => 'no',
    'initialassumedhoststate'       => 'unspecified',
    'initialassumedservicestate'    => 'unspecified',
    'breakdown'                     => 'days',
);
isa_ok($ma, 'Monitoring::Availability', 'create new Monitoring::Availability object');
my $result = $ma->calculate(
    'log_string'                    => $logs,
    'hosts'                         => ['mo'],
    'start'                         => 1334959200,
    'end'                           => 1335132000,
);
is_deeply($result, $expected, 'breakdown host') or diag("got:\n".Dumper($result)."\nbut expected:\n".Dumper($expected));

#########################
$result = $ma->calculate(
    'log_string'                    => $logs,
    'hosts'                         => ['mo'],
    'start'                         => 1334959200,
    'end'                           => 1335132100,
);
$expected->{'hosts'}->{'mo'}->{'time_up'} += 100;
$expected->{'hosts'}->{'mo'}->{'breakdown'}->{'2012-04-23'} = {
    'time_down' => 0,
    'time_indeterminate_notrunning' => 0,
    'scheduled_time_down' => 0,
    'scheduled_time_up' => 0,
    'time_unreachable' => 0,
    'time_indeterminate_nodata' => 0,
    'time_up' => 100,
    'scheduled_time_unreachable' => 0,
    'time_indeterminate_outside_timeperiod' => 0,
    'scheduled_time_indeterminate' => 0,
    'timestamp' => 1335132000
};
is_deeply($result, $expected, 'breakdown host') or diag("got:\n".Dumper($result)."\nbut expected:\n".Dumper($expected));


__DATA__
[1334959200] CURRENT HOST STATE: mo;UP;HARD;1;OK - 172.16.0.1: rta 25.610ms, lost 0%
[1335066684] HOST ALERT: mo;DOWN;HARD;5;CRITICAL - 172.16.0.1: Host unreachable @ 172.16.0.3. rta nan, lost 100%
[1335067266] HOST ALERT: mo;UP;HARD;1;OK - 172.16.0.1: rta 24.712ms, lost 0%
