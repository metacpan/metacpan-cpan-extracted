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
        plan tests => 19;
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
      'hosts' => {
        'n0_test_host_001' => { 'time_down' => 0, 'time_indeterminate_notrunning' => 0, 'scheduled_time_down' => 0, 'scheduled_time_up' => 0, 'time_unreachable' => 0, 'time_indeterminate_nodata' => 396597, 'time_indeterminate_outside_timeperiod' => 0, 'time_up' => 208203, 'scheduled_time_unreachable' => 0, 'scheduled_time_indeterminate' => 0 } },
      'services' => {
        'n0_test_host_001'      => {
            'n0_test_flap_19'       => { 'time_ok' => 208203, 'scheduled_time_critical' => 0, 'scheduled_time_unknown' => 0, 'scheduled_time_warning' => 0, 'scheduled_time_ok' => 0, 'time_indeterminate_notrunning' => 0, 'time_indeterminate_nodata' => 396597, 'time_indeterminate_outside_timeperiod' => 0, 'time_warning' => 0, 'time_critical' => 0, 'time_unknown' => 0, 'scheduled_time_indeterminate' => 0 },
            'n0_test_pending_06'    => { 'time_ok' => 208203, 'scheduled_time_critical' => 0, 'scheduled_time_unknown' => 0, 'scheduled_time_warning' => 0, 'scheduled_time_ok' => 0, 'time_indeterminate_notrunning' => 0, 'time_indeterminate_nodata' => 396597, 'time_indeterminate_outside_timeperiod' => 0, 'time_warning' => 0, 'time_critical' => 0, 'time_unknown' => 0, 'scheduled_time_indeterminate' => 0 },
            'n0_test_random_03'     => { 'time_ok' => 208203, 'scheduled_time_critical' => 0, 'scheduled_time_unknown' => 0, 'scheduled_time_warning' => 0, 'scheduled_time_ok' => 0, 'time_indeterminate_notrunning' => 0, 'time_indeterminate_nodata' => 396597, 'time_indeterminate_outside_timeperiod' => 0, 'time_warning' => 0, 'time_critical' => 0, 'time_unknown' => 0, 'scheduled_time_indeterminate' => 0 },
            'n0_test_ok_05'         => { 'time_ok' => 208203, 'scheduled_time_critical' => 0, 'scheduled_time_unknown' => 0, 'scheduled_time_warning' => 0, 'scheduled_time_ok' => 0, 'time_indeterminate_notrunning' => 0, 'time_indeterminate_nodata' => 396597, 'time_indeterminate_outside_timeperiod' => 0, 'time_warning' => 0, 'time_critical' => 0, 'time_unknown' => 0, 'scheduled_time_indeterminate' => 0 },
            'n0_test_unknown_04'    => { 'time_ok' => 0, 'scheduled_time_critical' => 0, 'scheduled_time_unknown' => 0, 'scheduled_time_warning' => 0, 'scheduled_time_ok' => 0, 'time_indeterminate_notrunning' => 0, 'time_indeterminate_nodata' => 396597, 'time_indeterminate_outside_timeperiod' => 0, 'time_warning' => 0, 'time_critical' => 0, 'time_unknown' => 208203, 'scheduled_time_indeterminate' => 0 },
            'n0_test_random_13'     => { 'time_ok' => 208203, 'scheduled_time_critical' => 0, 'scheduled_time_unknown' => 0, 'scheduled_time_warning' => 0, 'scheduled_time_ok' => 0, 'time_indeterminate_notrunning' => 0, 'time_indeterminate_nodata' => 396597, 'time_indeterminate_outside_timeperiod' => 0, 'time_warning' => 0, 'time_critical' => 0, 'time_unknown' => 0, 'scheduled_time_indeterminate' => 0 },
            'n0_test_ok_14'         => { 'time_ok' => 208203, 'scheduled_time_critical' => 0, 'scheduled_time_unknown' => 0, 'scheduled_time_warning' => 0, 'scheduled_time_ok' => 0, 'time_indeterminate_notrunning' => 0, 'time_indeterminate_nodata' => 396597, 'time_indeterminate_outside_timeperiod' => 0, 'time_warning' => 0, 'time_critical' => 0, 'time_unknown' => 0, 'scheduled_time_indeterminate' => 0 },
            'n0_test_ok_17'         => { 'time_ok' => 208203, 'scheduled_time_critical' => 0, 'scheduled_time_unknown' => 0, 'scheduled_time_warning' => 0, 'scheduled_time_ok' => 0, 'time_indeterminate_notrunning' => 0, 'time_indeterminate_nodata' => 396597, 'time_indeterminate_outside_timeperiod' => 0, 'time_warning' => 0, 'time_critical' => 0, 'time_unknown' => 0, 'scheduled_time_indeterminate' => 0 },
            'n0_test_random_02'     => { 'time_ok' => 208203, 'scheduled_time_critical' => 0, 'scheduled_time_unknown' => 0, 'scheduled_time_warning' => 0, 'scheduled_time_ok' => 0, 'time_indeterminate_notrunning' => 0, 'time_indeterminate_nodata' => 396597, 'time_indeterminate_outside_timeperiod' => 0, 'time_warning' => 0, 'time_critical' => 0, 'time_unknown' => 0, 'scheduled_time_indeterminate' => 0 },
            'n0_test_ok_12'         => { 'time_ok' => 208203, 'scheduled_time_critical' => 0, 'scheduled_time_unknown' => 0, 'scheduled_time_warning' => 0, 'scheduled_time_ok' => 0, 'time_indeterminate_notrunning' => 0, 'time_indeterminate_nodata' => 396597, 'time_indeterminate_outside_timeperiod' => 0, 'time_warning' => 0, 'time_critical' => 0, 'time_unknown' => 0, 'scheduled_time_indeterminate' => 0 },
            'n0_test_ok_08'         => { 'time_ok' => 208203, 'scheduled_time_critical' => 0, 'scheduled_time_unknown' => 0, 'scheduled_time_warning' => 0, 'scheduled_time_ok' => 0, 'time_indeterminate_notrunning' => 0, 'time_indeterminate_nodata' => 396597, 'time_indeterminate_outside_timeperiod' => 0, 'time_warning' => 0, 'time_critical' => 0, 'time_unknown' => 0, 'scheduled_time_indeterminate' => 0 },
            'n0_test_warning_18'    => { 'time_ok' => 0, 'scheduled_time_critical' => 0, 'scheduled_time_unknown' => 0, 'scheduled_time_warning' => 0, 'scheduled_time_ok' => 0, 'time_indeterminate_notrunning' => 0, 'time_indeterminate_nodata' => 396597, 'time_indeterminate_outside_timeperiod' => 0, 'time_warning' => 208203, 'time_critical' => 0, 'time_unknown' => 0, 'scheduled_time_indeterminate' => 0 },
            'n0_test_ok_11'         => { 'time_ok' => 208203, 'scheduled_time_critical' => 0, 'scheduled_time_unknown' => 0, 'scheduled_time_warning' => 0, 'scheduled_time_ok' => 0, 'time_indeterminate_notrunning' => 0, 'time_indeterminate_nodata' => 396597, 'time_indeterminate_outside_timeperiod' => 0, 'time_warning' => 0, 'time_critical' => 0, 'time_unknown' => 0, 'scheduled_time_indeterminate' => 0 },
            'n0_test_ok_07'         => { 'time_ok' => 208203, 'scheduled_time_critical' => 0, 'scheduled_time_unknown' => 0, 'scheduled_time_warning' => 0, 'scheduled_time_ok' => 0, 'time_indeterminate_notrunning' => 0, 'time_indeterminate_nodata' => 396597, 'time_indeterminate_outside_timeperiod' => 0, 'time_warning' => 0, 'time_critical' => 0, 'time_unknown' => 0, 'scheduled_time_indeterminate' => 0 },
            'n0_test_flap_00'       => { 'time_ok' => 208203, 'scheduled_time_critical' => 0, 'scheduled_time_unknown' => 0, 'scheduled_time_warning' => 0, 'scheduled_time_ok' => 0, 'time_indeterminate_notrunning' => 0, 'time_indeterminate_nodata' => 396597, 'time_indeterminate_outside_timeperiod' => 0, 'time_warning' => 0, 'time_critical' => 0, 'time_unknown' => 0, 'scheduled_time_indeterminate' => 0 },
            'n0_test_ok_10'         => { 'time_ok' => 208203, 'scheduled_time_critical' => 0, 'scheduled_time_unknown' => 0, 'scheduled_time_warning' => 0, 'scheduled_time_ok' => 0, 'time_indeterminate_notrunning' => 0, 'time_indeterminate_nodata' => 396597, 'time_indeterminate_outside_timeperiod' => 0, 'time_warning' => 0, 'time_critical' => 0, 'time_unknown' => 0, 'scheduled_time_indeterminate' => 0 },
            'n0_test_ok_09'         => { 'time_ok' => 208203, 'scheduled_time_critical' => 0, 'scheduled_time_unknown' => 0, 'scheduled_time_warning' => 0, 'scheduled_time_ok' => 0, 'time_indeterminate_notrunning' => 0, 'time_indeterminate_nodata' => 396597, 'time_indeterminate_outside_timeperiod' => 0, 'time_warning' => 0, 'time_critical' => 0, 'time_unknown' => 0, 'scheduled_time_indeterminate' => 0 },
            'n0_test_ok_01'         => { 'time_ok' => 208203, 'scheduled_time_critical' => 0, 'scheduled_time_unknown' => 0, 'scheduled_time_warning' => 0, 'scheduled_time_ok' => 0, 'time_indeterminate_notrunning' => 0, 'time_indeterminate_nodata' => 396597, 'time_indeterminate_outside_timeperiod' => 0, 'time_warning' => 0, 'time_critical' => 0, 'time_unknown' => 0, 'scheduled_time_indeterminate' => 0 },
            'n0_test_warning_16'    => { 'time_ok' => 0, 'scheduled_time_critical' => 0, 'scheduled_time_unknown' => 0, 'scheduled_time_warning' => 0, 'scheduled_time_ok' => 0, 'time_indeterminate_notrunning' => 0, 'time_indeterminate_nodata' => 396597, 'time_indeterminate_outside_timeperiod' => 0, 'time_warning' => 208203, 'time_critical' => 0, 'time_unknown' => 0, 'scheduled_time_indeterminate' => 0 },
            'n0_test_random_15'     => { 'time_ok' => 208203, 'scheduled_time_critical' => 0, 'scheduled_time_unknown' => 0, 'scheduled_time_warning' => 0, 'scheduled_time_ok' => 0, 'time_indeterminate_notrunning' => 0, 'time_indeterminate_nodata' => 396597, 'time_indeterminate_outside_timeperiod' => 0, 'time_warning' => 0, 'time_critical' => 0, 'time_unknown' => 0, 'scheduled_time_indeterminate' => 0 }
    }
  }
};

my $expected_condensed_log = [
    { 'start' => '2010-01-22 00:00:00', 'end' => '2010-01-22 22:11:09', 'duration' => '0d 22h 11m 9s',  'type' => 'HOST UP (HARD)',     'plugin_output' => 'n0_test_host_001 (checked by mo) OK: ok hostcheck', 'class' => 'UP', 'in_downtime' => 0 },
];

my $expected_full_log = [
    { 'start' => '2010-01-08 15:50:52', 'end' => '2010-01-17 14:58:55', 'duration' => '8d 23h 8m 3s',   'type' => 'PROGRAM (RE)START',  'plugin_output' => 'Program start',                 'class' => 'INDETERMINATE' },
    { 'start' => '2010-01-17 14:58:55', 'end' => '2010-01-17 17:02:26', 'duration' => '0d 2h 3m 31s',   'type' => 'PROGRAM (RE)START',  'plugin_output' => 'Program start',                 'class' => 'INDETERMINATE' },
    { 'start' => '2010-01-17 17:02:26', 'end' => '2010-01-17 17:02:28', 'duration' => '0d 0h 0m 2s',    'type' => 'PROGRAM END',        'plugin_output' => 'Normal program termination',    'class' => 'INDETERMINATE' },
    { 'start' => '2010-01-17 17:02:28', 'end' => '2010-01-17 17:03:55', 'duration' => '0d 0h 1m 27s',   'type' => 'PROGRAM (RE)START',  'plugin_output' => 'Program start',                 'class' => 'INDETERMINATE' },
    { 'start' => '2010-01-17 17:03:55', 'end' => '2010-01-17 17:03:58', 'duration' => '0d 0h 0m 3s',    'type' => 'PROGRAM END',        'plugin_output' => 'Normal program termination',    'class' => 'INDETERMINATE' },
    { 'start' => '2010-01-17 17:03:58', 'end' => '2010-01-17 17:04:57', 'duration' => '0d 0h 0m 59s',   'type' => 'PROGRAM (RE)START',  'plugin_output' => 'Program start',                 'class' => 'INDETERMINATE' },
    { 'start' => '2010-01-17 17:04:57', 'end' => '2010-01-17 17:05:00', 'duration' => '0d 0h 0m 3s',    'type' => 'PROGRAM END',        'plugin_output' => 'Normal program termination',    'class' => 'INDETERMINATE' },
    { 'start' => '2010-01-17 17:05:00', 'end' => '2010-01-22 00:00:00', 'duration' => '4d 6h 55m 0s',   'type' => 'PROGRAM (RE)START',  'plugin_output' => 'Program start',                 'class' => 'INDETERMINATE' },
    { 'start' => '2010-01-22 00:00:00', 'end' => '2010-01-22 22:11:09', 'duration' => '0d 22h 11m 9s',  'type' => 'HOST UP (HARD)',     'plugin_output' => 'n0_test_host_001 (checked by mo) OK: ok hostcheck', 'class' => 'UP', 'in_downtime' => 0 },
    { 'start' => '2010-01-22 22:11:09', 'end' => '2010-01-22 22:12:22', 'duration' => '0d 0h 1m 13s',   'type' => 'PROGRAM END',        'plugin_output' => 'Normal program termination',    'class' => 'INDETERMINATE' },
    { 'start' => '2010-01-22 22:12:22', 'end' => '2010-01-23 23:03:54', 'duration' => '1d 0h 51m 32s',  'type' => 'PROGRAM (RE)START',  'plugin_output' => 'Program start',                 'class' => 'INDETERMINATE' },
    { 'start' => '2010-01-23 23:03:54', 'end' => '2010-01-23 23:03:57', 'duration' => '0d 0h 0m 3s',    'type' => 'PROGRAM END',        'plugin_output' => 'Normal program termination',    'class' => 'INDETERMINATE' },
    { 'start' => '2010-01-23 23:03:57', 'end' => '2010-01-24 09:50:03', 'duration' => '0d 10h 46m 6s+', 'type' => 'PROGRAM (RE)START',  'plugin_output' => 'Program start',                 'class' => 'INDETERMINATE' },
];

#########################
# avail.cgi?t1=1263718203&t2=1264323003&show_log_entries=&full_log_entries=&host=n0_test_host_001&assumeinitialstates=yes&assumestateretention=yes&assumestatesduringnotrunning=yes&includesoftstates=no&initialassumedhoststate=0&initialassumedservicestate=0&timeperiod=[+Current+time+range+]&backtrack=4
my $ma = Monitoring::Availability->new(
    'verbose'                       => 0,
    'backtrack'                     => 4,
    'assumestateretention'          => 'yes',
    'assumeinitialstates'           => 'yes',
    'assumestatesduringnotrunning'  => 'yes',
    'initialassumedhoststate'       => 'unspecified',
    'initialassumedservicestate'    => 'unspecified',
);
isa_ok($ma, 'Monitoring::Availability', 'create new Monitoring::Availability object');
my $result = $ma->calculate(
    'log_string'                    => $logs,
    'hosts'                         => ['n0_test_host_001'],
    'services'                      => [
        { 'service' => 'n0_test_flap_19',       'host' => 'n0_test_host_001' },
        { 'service' => 'n0_test_random_03',     'host' => 'n0_test_host_001' },
        { 'service' => 'n0_test_pending_06',    'host' => 'n0_test_host_001' },
        { 'service' => 'n0_test_ok_05',         'host' => 'n0_test_host_001' },
        { 'service' => 'n0_test_unknown_04',    'host' => 'n0_test_host_001' },
        { 'service' => 'n0_test_random_13',     'host' => 'n0_test_host_001' },
        { 'service' => 'n0_test_ok_14',         'host' => 'n0_test_host_001' },
        { 'service' => 'n0_test_ok_17',         'host' => 'n0_test_host_001' },
        { 'service' => 'n0_test_random_02',     'host' => 'n0_test_host_001' },
        { 'service' => 'n0_test_ok_12',         'host' => 'n0_test_host_001' },
        { 'service' => 'n0_test_ok_08',         'host' => 'n0_test_host_001' },
        { 'service' => 'n0_test_warning_18',    'host' => 'n0_test_host_001' },
        { 'service' => 'n0_test_ok_11',         'host' => 'n0_test_host_001' },
        { 'service' => 'n0_test_ok_07',         'host' => 'n0_test_host_001' },
        { 'service' => 'n0_test_flap_00',       'host' => 'n0_test_host_001' },
        { 'service' => 'n0_test_ok_10',         'host' => 'n0_test_host_001' },
        { 'service' => 'n0_test_ok_09',         'host' => 'n0_test_host_001' },
        { 'service' => 'n0_test_warning_16',    'host' => 'n0_test_host_001' },
        { 'service' => 'n0_test_ok_01',         'host' => 'n0_test_host_001' },
        { 'service' => 'n0_test_random_15',     'host' => 'n0_test_host_001' }
      ],
    'start'                         => 1263718203,
    'end'                           => 1264323003,
    'timeformat'                    => '%Y-%m-%d %H:%M:%S',
);

is_deeply($result, $expected, 'host with services') or diag("got:\n".Dumper($result)."\nbut expected:\n".Dumper($expected));
my $condensed_logs = $ma->get_condensed_logs();
# test will fail on windows because of a different used timezone
TestUtils::check_array_one_by_one($expected_condensed_log, $condensed_logs, 'condensed logs');

my $full_logs = $ma->get_full_logs();
# test will fail on windows because of a different used timezone
TestUtils::check_array_one_by_one($expected_full_log, $full_logs, 'full logs');

__DATA__
[1262962252] Nagios 3.2.0 starting... (PID=7873)
[1263736735] Nagios 3.2.0 starting... (PID=528)
[1263744146] Caught SIGTERM, shutting down...
[1263744148] Nagios 3.2.0 starting... (PID=21311)
[1263744235] Caught SIGTERM, shutting down...
[1263744238] Nagios 3.2.0 starting... (PID=21471)
[1263744297] Caught SIGTERM, shutting down...
[1263744300] Nagios 3.2.0 starting... (PID=21647)
[1264114800] CURRENT HOST STATE: n0_test_host_001;UP;HARD;1;n0_test_host_001 (checked by mo) OK: ok hostcheck
[1264114800] CURRENT SERVICE STATE: n0_test_host_001;n0_test_flap_00;OK;HARD;1;n0_test_host_001 (checked by mo) FLAP: up n0_test_flap_00 up
[1264114800] CURRENT SERVICE STATE: n0_test_host_001;n0_test_flap_19;OK;HARD;1;n0_test_host_001 (checked by mo) FLAP: up n0_test_flap_19 up
[1264114800] CURRENT SERVICE STATE: n0_test_host_001;n0_test_ok_01;OK;HARD;1;n0_test_host_001 (checked by mo) OK: ok n0_test_ok_01
[1264114800] CURRENT SERVICE STATE: n0_test_host_001;n0_test_ok_05;OK;HARD;1;n0_test_host_001 (checked by mo) OK: ok n0_test_ok_05
[1264114800] CURRENT SERVICE STATE: n0_test_host_001;n0_test_ok_07;OK;HARD;1;n0_test_host_001 (checked by mo) OK: ok n0_test_ok_07
[1264114800] CURRENT SERVICE STATE: n0_test_host_001;n0_test_ok_08;OK;HARD;1;n0_test_host_001 (checked by mo) OK: ok n0_test_ok_08
[1264114800] CURRENT SERVICE STATE: n0_test_host_001;n0_test_ok_09;OK;HARD;1;n0_test_host_001 (checked by mo) OK: ok n0_test_ok_09
[1264114800] CURRENT SERVICE STATE: n0_test_host_001;n0_test_ok_10;OK;HARD;1;n0_test_host_001 (checked by mo) OK: ok n0_test_ok_10
[1264114800] CURRENT SERVICE STATE: n0_test_host_001;n0_test_ok_11;OK;HARD;1;n0_test_host_001 (checked by mo) OK: ok n0_test_ok_11
[1264114800] CURRENT SERVICE STATE: n0_test_host_001;n0_test_ok_12;OK;HARD;1;n0_test_host_001 (checked by mo) OK: ok n0_test_ok_12
[1264114800] CURRENT SERVICE STATE: n0_test_host_001;n0_test_ok_14;OK;HARD;1;n0_test_host_001 (checked by mo) OK: ok n0_test_ok_14
[1264114800] CURRENT SERVICE STATE: n0_test_host_001;n0_test_ok_17;OK;HARD;1;n0_test_host_001 (checked by mo) OK: ok n0_test_ok_17
[1264114800] CURRENT SERVICE STATE: n0_test_host_001;n0_test_pending_06;OK;HARD;1;
[1264114800] CURRENT SERVICE STATE: n0_test_host_001;n0_test_random_02;OK;HARD;1;n0_test_host_001 (checked by mo) OK: random n0_test_random_02 ok
[1264114800] CURRENT SERVICE STATE: n0_test_host_001;n0_test_random_03;OK;HARD;1;n0_test_host_001 (checked by mo) OK: random n0_test_random_03 ok
[1264114800] CURRENT SERVICE STATE: n0_test_host_001;n0_test_random_13;OK;HARD;1;n0_test_host_001 (checked by mo) OK: random n0_test_random_13 ok
[1264114800] CURRENT SERVICE STATE: n0_test_host_001;n0_test_random_15;OK;HARD;1;n0_test_host_001 (checked by mo) OK: random n0_test_random_15 ok
[1264114800] CURRENT SERVICE STATE: n0_test_host_001;n0_test_unknown_04;UNKNOWN;HARD;3;n0_test_host_001 (checked by mo) UNKNOWN: unknown n0_test_unknown_04
[1264114800] CURRENT SERVICE STATE: n0_test_host_001;n0_test_warning_16;WARNING;HARD;3;n0_test_host_001 (checked by mo) WARNING: warning n0_test_warning_16
[1264114800] CURRENT SERVICE STATE: n0_test_host_001;n0_test_warning_18;WARNING;HARD;3;n0_test_host_001 (checked by mo) WARNING: warning n0_test_warning_18
[1264194669] Caught SIGTERM, shutting down...
[1264194742] Nagios 3.2.0 starting... (PID=10418)
[1264284234] Caught SIGTERM, shutting down...
[1264284237] Nagios 3.2.0 starting... (PID=22961)
