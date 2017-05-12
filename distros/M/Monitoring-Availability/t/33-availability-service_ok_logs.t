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
        plan tests => 63;
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
    'hosts' => {},
    'services' => {
        'n0_test_host_000' => {
            'n0_test_random_04' => {
                'time_ok'           => 604800,
                'time_warning'      => 0,
                'time_unknown'      => 0,
                'time_critical'     => 0,

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
    { 'start' => '2010-01-09 00:00:00', end => '2010-01-17 14:58:55', 'duration' => '8d 14h 58m 55s',  'type' => 'SERVICE OK (HARD)', plugin_output => 'n0_test_host_000 (checked by mo) REVOVERED: random n0_test_random_04 recovered', 'class' => 'OK', 'in_downtime' => 0 },
    { 'start' => '2010-01-18 00:00:00', end => '2010-01-19 00:00:00', 'duration' => '1d 0h 0m 0s',     'type' => 'SERVICE OK (HARD)', plugin_output => 'n0_test_host_000 (checked by mo) REVOVERED: random n0_test_random_04 recovered', 'class' => 'OK', 'in_downtime' => 0 },
    { 'start' => '2010-01-19 00:00:00', end => '2010-01-20 00:00:00', 'duration' => '1d 0h 0m 0s',     'type' => 'SERVICE OK (HARD)', plugin_output => 'n0_test_host_000 (checked by mo) REVOVERED: random n0_test_random_04 recovered', 'class' => 'OK', 'in_downtime' => 0 },
    { 'start' => '2010-01-20 00:00:00', end => '2010-01-20 22:16:24', 'duration' => '0d 22h 16m 24s+', 'type' => 'SERVICE OK (HARD)', plugin_output => 'n0_test_host_000 (checked by mo) REVOVERED: random n0_test_random_04 recovered', 'class' => 'OK', 'in_downtime' => 0 },
];
my $expected_full_log = [
    { 'start' => '2010-01-08 15:50:52', 'end' => '2010-01-09 00:00:00', 'duration' => '0d 8h 9m 8s',     'type' => 'PROGRAM (RE)START', 'plugin_output' => 'Program start', 'class' => 'INDETERMINATE' },
    { 'start' => '2010-01-09 00:00:00', 'end' => '2010-01-17 14:58:55', 'duration' => '8d 14h 58m 55s',  'type' => 'SERVICE OK (HARD)', 'plugin_output' => 'n0_test_host_000 (checked by mo) REVOVERED: random n0_test_random_04 recovered', 'class' => 'OK', 'in_downtime' => 0 },
    { 'start' => '2010-01-17 14:58:55', 'end' => '2010-01-17 17:02:26', 'duration' => '0d 2h 3m 31s',    'type' => 'PROGRAM (RE)START', 'plugin_output' => 'Program start', 'class' => 'INDETERMINATE' },
    { 'start' => '2010-01-17 17:02:26', 'end' => '2010-01-17 17:02:28', 'duration' => '0d 0h 0m 2s',     'type' => 'PROGRAM END',       'plugin_output' => 'Normal program termination', 'class' => 'INDETERMINATE' },
    { 'start' => '2010-01-17 17:02:28', 'end' => '2010-01-17 17:03:55', 'duration' => '0d 0h 1m 27s',    'type' => 'PROGRAM (RE)START', 'plugin_output' => 'Program start', 'class' => 'INDETERMINATE' },
    { 'start' => '2010-01-17 17:03:55', 'end' => '2010-01-17 17:03:58', 'duration' => '0d 0h 0m 3s',     'type' => 'PROGRAM END',       'plugin_output' => 'Normal program termination', 'class' => 'INDETERMINATE' },
    { 'start' => '2010-01-17 17:03:58', 'end' => '2010-01-17 17:04:57', 'duration' => '0d 0h 0m 59s',    'type' => 'PROGRAM (RE)START', 'plugin_output' => 'Program start', 'class' => 'INDETERMINATE' },
    { 'start' => '2010-01-17 17:04:57', 'end' => '2010-01-17 17:05:00', 'duration' => '0d 0h 0m 3s',     'type' => 'PROGRAM END',       'plugin_output' => 'Normal program termination', 'class' => 'INDETERMINATE' },
    { 'start' => '2010-01-17 17:05:00', 'end' => '2010-01-18 00:00:00', 'duration' => '0d 6h 55m 0s',    'type' => 'PROGRAM (RE)START', 'plugin_output' => 'Program start', 'class' => 'INDETERMINATE' },
    { 'start' => '2010-01-18 00:00:00', 'end' => '2010-01-19 00:00:00', 'duration' => '1d 0h 0m 0s',     'type' => 'SERVICE OK (HARD)', 'plugin_output' => 'n0_test_host_000 (checked by mo) REVOVERED: random n0_test_random_04 recovered', 'class' => 'OK', 'in_downtime' => 0 },
    { 'start' => '2010-01-19 00:00:00', 'end' => '2010-01-20 00:00:00', 'duration' => '1d 0h 0m 0s',     'type' => 'SERVICE OK (HARD)', 'plugin_output' => 'n0_test_host_000 (checked by mo) REVOVERED: random n0_test_random_04 recovered', 'class' => 'OK', 'in_downtime' => 0 },
    { 'start' => '2010-01-20 00:00:00', 'end' => '2010-01-20 22:16:24', 'duration' => '0d 22h 16m 24s+', 'type' => 'SERVICE OK (HARD)', 'plugin_output' => 'n0_test_host_000 (checked by mo) REVOVERED: random n0_test_random_04 recovered', 'class' => 'OK', 'in_downtime' => 0 },
];

#########################
# avail.cgi?host=n0_test_host_000&service=n0_test_random_04&t1=1263417384&t2=1264022184&backtrack=4&assumestateretention=yes&assumeinitialstates=yes&assumestatesduringnotrunning=yes&initialassumedhoststate=0&initialassumedservicestate=0&show_log_entries&full_log_entries&showscheduleddowntime=yes
my $ma = Monitoring::Availability->new(
    'verbose'                       => 0,
    'backtrack'                     => 4,
    'assumestateretention'          => 'yes',
    'assumeinitialstates'           => 'yes',
    'assumestatesduringnotrunning'  => 'yes',
    'initialassumedhoststate'       => 'unspecified',
    'initialassumedservicestate'    => 'unspecified',
    'timeformat'                    => '%Y-%m-%d %H:%M:%S',
);
isa_ok($ma, 'Monitoring::Availability', 'create new Monitoring::Availability object');
my $result = $ma->calculate(
    'log_string'                    => $logs,
    'services'                      => [{'host' => 'n0_test_host_000', 'service' => 'n0_test_random_04'}],
    'start'                         => 1263417384,
    'end'                           => 1264022184,
);
is_deeply($result, $expected, 'ok service') or diag("got:\n".Dumper($result)."\nbut expected:\n".Dumper($expected));

my $condensed_logs = $ma->get_condensed_logs();
# test will fail on windows because of a different used timezone
TestUtils::check_array_one_by_one($expected_log, $condensed_logs, 'condensed logs');

my $full_logs = $ma->get_full_logs();
# test will fail on windows because of a different used timezone
TestUtils::check_array_one_by_one($expected_full_log, $full_logs, 'full logs');


#################################
# now check with initial assumed state "unknown"
$result = $ma->calculate(
    'log_string'                    => $logs,
    'services'                      => [{'host' => 'n0_test_host_000', 'service' => 'n0_test_random_04'}],
    'start'                         => 1263417384,
    'end'                           => 1264022184,
    'initialassumedservicestate'    => 'unknown',
);
is_deeply($result, $expected, 'ok service with initial unknown') or diag("got:\n".Dumper($result)."\nbut expected:\n".Dumper($expected));

my $additional_logs = [
    { 'start' => '2010-01-08 15:50:51', 'end' => '2010-01-08 15:50:52', 'duration' => '0d 0h 0m 1s', 'type' => 'SERVICE UNKNOWN (HARD)', 'plugin_output' => 'First Service State Assumed (Faked Log Entry)', 'class' => 'UNKNOWN' },
];
$condensed_logs = $ma->get_condensed_logs();
# test will fail on windows because of a different used timezone
TestUtils::check_array_one_by_one([@{$additional_logs}, @{$expected_log}], $condensed_logs, 'condensed logs with initial unknown');

$full_logs = $ma->get_full_logs();
# test will fail on windows because of a different used timezone
TestUtils::check_array_one_by_one([@{$additional_logs}, @{$expected_full_log}], $full_logs, 'full logs with initial unknown');


#################################
# now check with initial state "current"
$result = $ma->calculate(
    'log_string'                    => $logs,
    'services'                      => [{'host' => 'n0_test_host_000', 'service' => 'n0_test_random_04'}],
    'start'                         => 1263417384,
    'end'                           => 1264022184,
    'initialassumedservicestate'    => 'current',
    'initial_states'                => { 'services' => { 'n0_test_host_000' => { 'n0_test_random_04' => 'warning' }}},
);
is_deeply($result, $expected, 'ok service with initial current') or diag("got:\n".Dumper($result)."\nbut expected:\n".Dumper($expected));

$additional_logs = [
    { 'start' => '2010-01-08 15:50:51', 'end' => '2010-01-08 15:50:52', 'duration' => '0d 0h 0m 1s', 'type' => 'SERVICE WARNING (HARD)', 'plugin_output' => 'First Service State Assumed (Faked Log Entry)', 'class' => 'WARNING' },
];
$condensed_logs = $ma->get_condensed_logs();
# test will fail on windows because of a different used timezone
TestUtils::check_array_one_by_one([@{$additional_logs}, @{$expected_log}], $condensed_logs, 'condensed logs with initial unknown');

$full_logs = $ma->get_full_logs();
# test will fail on windows because of a different used timezone
TestUtils::check_array_one_by_one([@{$additional_logs}, @{$expected_full_log}], $full_logs, 'full logs with initial unknown');


#################################
__DATA__
[1262962252] Nagios 3.2.0 starting... (PID=7873)
[1262991600] CURRENT SERVICE STATE: n0_test_host_000;n0_test_random_04;OK;HARD;1;n0_test_host_000 (checked by mo) REVOVERED: random n0_test_random_04 recovered
[1263736735] Nagios 3.2.0 starting... (PID=528)
[1263744146] Caught SIGTERM, shutting down...
[1263744148] Nagios 3.2.0 starting... (PID=21311)
[1263744235] Caught SIGTERM, shutting down...
[1263744238] Nagios 3.2.0 starting... (PID=21471)
[1263744297] Caught SIGTERM, shutting down...
[1263744300] Nagios 3.2.0 starting... (PID=21647)
[1263769200] CURRENT SERVICE STATE: n0_test_host_000;n0_test_random_04;OK;HARD;1;n0_test_host_000 (checked by mo) REVOVERED: random n0_test_random_04 recovered
[1263855600] CURRENT SERVICE STATE: n0_test_host_000;n0_test_random_04;OK;HARD;1;n0_test_host_000 (checked by mo) REVOVERED: random n0_test_random_04 recovered
[1263942000] CURRENT SERVICE STATE: n0_test_host_000;n0_test_random_04;OK;HARD;1;n0_test_host_000 (checked by mo) REVOVERED: random n0_test_random_04 recovered
