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
        plan tests => 30;
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

my $options = {
    'verbose'                       => 0,
    'backtrack'                     => 4,
    'assumestateretention'          => 'yes',
    'assumeinitialstates'           => 'yes',
    'assumestatesduringnotrunning'  => 'yes',
    'initialassumedhoststate'       => 'unspecified',
    'initialassumedservicestate'    => 'unspecified',
    'timeformat'                    => '%Y-%m-%d %H:%M:%S',
    'rpttimeperiod'                 => '',
};
my $expected = {
    'hosts' => {},
    'services' => {
        'testhost' => {
            'testservice' => {
                'time_ok'           => 230,
                'time_warning'      => 0,
                'time_unknown'      => 0,
                'time_critical'     => 70,

                'scheduled_time_ok'             => 0,
                'scheduled_time_warning'        => 0,
                'scheduled_time_unknown'        => 0,
                'scheduled_time_critical'       => 0,
                'scheduled_time_indeterminate'  => 0,

                'time_indeterminate_nodata'     => 0,
                'time_indeterminate_notrunning' => 0,
                'time_indeterminate_outside_timeperiod' => 0,
            }
        }
    }
};

my $expected_log = [
    { 'plugin_output' => 'service is ok',   'duration' => '0d 0h 0m 40s', 'class' => 'OK',       'type' => 'SERVICE OK (HARD)',       'end' => '2010-01-09 00:00:40', 'start' => '2010-01-09 00:00:00', 'in_downtime' => 0 },
    { 'plugin_output' => 'service is down', 'duration' => '0d 0h 1m 10s', 'class' => 'CRITICAL', 'type' => 'SERVICE CRITICAL (HARD)', 'end' => '2010-01-09 00:01:50', 'start' => '2010-01-09 00:00:40', 'in_downtime' => 0 },
    { 'plugin_output' => 'service is ok',   'duration' => '0d 0h 3m 10s', 'class' => 'OK',       'type' => 'SERVICE OK (HARD)',       'end' => '2010-01-09 00:05:00', 'start' => '2010-01-09 00:01:50', 'in_downtime' => 0 },
];
my $expected_full_log = [
    { 'plugin_output' => 'Program start',   'duration' => '0d 0h 0m 0s',  'class' => 'INDETERMINATE', 'type' => 'PROGRAM (RE)START',       'end' => '2010-01-09 00:00:00', 'start' => '2010-01-09 00:00:00' },
    { 'plugin_output' => 'service is ok',   'duration' => '0d 0h 0m 40s', 'class' => 'OK',            'type' => 'SERVICE OK (HARD)',       'end' => '2010-01-09 00:00:40', 'start' => '2010-01-09 00:00:00', 'in_downtime' => 0 },
    { 'plugin_output' => 'service is down', 'duration' => '0d 0h 1m 10s', 'class' => 'CRITICAL',      'type' => 'SERVICE CRITICAL (HARD)', 'end' => '2010-01-09 00:01:50', 'start' => '2010-01-09 00:00:40', 'in_downtime' => 0 },
    { 'plugin_output' => 'service is ok',   'duration' => '0d 0h 3m 10s', 'class' => 'OK',            'type' => 'SERVICE OK (HARD)',       'end' => '2010-01-09 00:05:00', 'start' => '2010-01-09 00:01:50', 'in_downtime' => 0 },
    {                                       'duration' => '0d 0h 0m 0s',                                                                   'end' => '2010-01-09 00:05:00', 'start' => '2010-01-09 00:05:00' },
    { 'plugin_output' => 'Normal program termination',
                                            'duration' => '0d 0h 0m 0s+', 'class' => 'INDETERMINATE', 'type' => 'PROGRAM END',             'end' => '2010-01-09 00:05:00', 'start' => '2010-01-09 00:05:00' },
];

#########################
my $ma = Monitoring::Availability->new(%{$options});
isa_ok($ma, 'Monitoring::Availability', 'create new Monitoring::Availability object');
my $result = $ma->calculate(
    'log_string'                    => $logs,
    'services'                      => [{'host' => 'testhost', 'service' => 'testservice'}],
    'start'                         => 1262991600,
    'end'                           => 1262991900,
);
is_deeply($result, $expected, 'ok service') or diag("got:\n".Dumper($result)."\nbut expected:\n".Dumper($expected));

my $condensed_logs = $ma->get_condensed_logs();
TestUtils::check_array_one_by_one($expected_log, $condensed_logs, 'condensed logs');

my $full_logs = $ma->get_full_logs();
TestUtils::check_array_one_by_one($expected_full_log, $full_logs, 'full logs');


#########################
# now with timeperiod
$expected_log = [
    { 'plugin_output' => 'service is ok',   'duration' => '0d 0h 0m 0s',  'class' => 'OK',       'type' => 'SERVICE OK (HARD)',       'end' => '2010-01-09 00:00:00', 'start' => '2010-01-09 00:00:00', 'in_downtime' => 0 },
    { 'plugin_output' => 'service is down', 'duration' => '0d 0h 1m 0s',  'class' => 'CRITICAL', 'type' => 'SERVICE CRITICAL (HARD)', 'end' => '2010-01-09 00:01:40', 'start' => '2010-01-09 00:00:40', 'in_downtime' => 0 },
    { 'plugin_output' => 'service is ok',   'duration' => '0d 0h 3m 10s', 'class' => 'OK',       'type' => 'SERVICE OK (HARD)',       'end' => '2010-01-09 00:05:00', 'start' => '2010-01-09 00:01:50', 'in_downtime' => 0 },
];
$expected_full_log = [
    { 'plugin_output' => 'Program start',                  'duration' => '0d 0h 0m 0s',  'class' => 'INDETERMINATE',    'type' => 'PROGRAM (RE)START',          'end' => '2010-01-09 00:00:00', 'start' => '2010-01-09 00:00:00' },
    { 'plugin_output' => 'service is ok',                  'duration' => '0d 0h 0m 0s',  'class' => 'OK',               'type' => 'SERVICE OK (HARD)',          'end' => '2010-01-09 00:00:00', 'start' => '2010-01-09 00:00:00', 'in_downtime' => 0 },
    { 'plugin_output' => 'entering timeperiod: workhours', 'duration' => '0d 0h 0m 30s', 'class' => 'INDETERMINATE',    'type' => 'TIMEPERIOD START',           'end' => '2010-01-09 00:00:30', 'start' => '2010-01-09 00:00:00' },
    { 'plugin_output' => 'leaving timeperiod: workhours',  'duration' => '0d 0h 0m 10s', 'class' => 'INDETERMINATE',    'type' => 'TIMEPERIOD STOP',            'end' => '2010-01-09 00:00:40', 'start' => '2010-01-09 00:00:30' },
    { 'plugin_output' => 'service is down',                'duration' => '0d 0h 1m 0s',  'class' => 'CRITICAL',         'type' => 'SERVICE CRITICAL (HARD)',    'end' => '2010-01-09 00:01:40', 'start' => '2010-01-09 00:00:40', 'in_downtime' => 0 },
    { 'plugin_output' => 'entering timeperiod: workhours', 'duration' => '0d 0h 0m 10s', 'class' => 'INDETERMINATE',    'type' => 'TIMEPERIOD START',           'end' => '2010-01-09 00:01:50', 'start' => '2010-01-09 00:01:40' },
    { 'plugin_output' => 'service is ok',                  'duration' => '0d 0h 3m 10s', 'class' => 'OK',               'type' => 'SERVICE OK (HARD)',          'end' => '2010-01-09 00:05:00', 'start' => '2010-01-09 00:01:50', 'in_downtime' => 0 },
    {                                                      'duration' => '0d 0h 0m 0s',                                                                         'end' => '2010-01-09 00:05:00', 'start' => '2010-01-09 00:05:00' },
    { 'plugin_output' => 'Normal program termination',     'duration' => '0d 0h 0m 0s+', 'class' => 'INDETERMINATE',    'type' => 'PROGRAM END',                'end' => '2010-01-09 00:05:00', 'start' => '2010-01-09 00:05:00' }
];
$expected->{'services'}->{'testhost'}->{'testservice'}->{'time_ok'}       = 220;
$expected->{'services'}->{'testhost'}->{'testservice'}->{'time_critical'} = 10;
$expected->{'services'}->{'testhost'}->{'testservice'}->{'time_indeterminate_outside_timeperiod'} = 70;
$options->{'rpttimeperiod'} = 'workhours';
$ma = Monitoring::Availability->new(%{$options});
isa_ok($ma, 'Monitoring::Availability', 'create new Monitoring::Availability object');
$result = $ma->calculate(
    'log_string'                    => $logs,
    'services'                      => [{'host' => 'testhost', 'service' => 'testservice'}],
    'start'                         => 1262991600,
    'end'                           => 1262991900,
);
is_deeply($result, $expected, 'ok service') or diag("got:\n".Dumper($result)."\nbut expected:\n".Dumper($expected));

$condensed_logs = $ma->get_condensed_logs();
TestUtils::check_array_one_by_one($expected_log, $condensed_logs, 'condensed logs');

$full_logs = $ma->get_full_logs();
TestUtils::check_array_one_by_one($expected_full_log, $full_logs, 'full logs');


#################################
__DATA__
[1262991600] Nagios 3.2.0 starting... (PID=7873)
[1262991600] CURRENT SERVICE STATE: testhost;testservice;OK;HARD;1;service is ok
[1262991600] TIMEPERIOD TRANSITION: workhours;-1;1
[1262991630] TIMEPERIOD TRANSITION: workhours;1;0
[1262991640] SERVICE ALERT: testhost;testservice;CRITICAL;HARD;1;service is down
[1262991700] TIMEPERIOD TRANSITION: workhours;0;1
[1262991710] SERVICE ALERT: testhost;testservice;OK;HARD;1;service is ok
[1262991900] Caught SIGTERM, shutting down...
