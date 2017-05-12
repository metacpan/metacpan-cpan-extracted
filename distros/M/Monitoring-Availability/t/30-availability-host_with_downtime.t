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
        plan tests => 14;
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
        'n0_test_host_000' => {
            'time_up'           => 507245,
            'time_down'         => 0,
            'time_unreachable'  => 0,

            'scheduled_time_up'             => 680,
            'scheduled_time_down'           => 0,
            'scheduled_time_unreachable'    => 0,
            'scheduled_time_indeterminate'  => 0,

            'time_indeterminate_nodata'     => 97550,
            'time_indeterminate_notrunning' => 5,
            'time_indeterminate_outside_timeperiod' => 0,
        }
    }
};

my $expected_condensed_log = [
    { 'start' => '2010-01-09 00:00:00', end => '2010-01-09 14:11:33', 'duration' => '0d 14h 11m 33s',  'type' => 'HOST UP (HARD)',      plugin_output => 'n0_test_host_000 ...',        'class' => 'UP', 'in_downtime' => 0 },
    { 'start' => '2010-01-09 14:11:33', end => '2010-01-09 14:22:53', 'duration' => '0d 0h 11m 20s',   'type' => 'HOST DOWNTIME START', plugin_output => 'Start of scheduled downtime', 'class' => 'INDETERMINATE', 'in_downtime' => 1 },
    { 'start' => '2010-01-09 14:22:53', end => '2010-01-09 14:25:55', 'duration' => '0d 0h 3m 2s',     'type' => 'HOST DOWNTIME STOP',  plugin_output => 'End of scheduled downtime',   'class' => 'INDETERMINATE', 'in_downtime' => 0 },
];

my $expected_full_log = [
    { 'start' => '2010-01-08 15:50:52', end => '2010-01-09 00:00:00', 'duration' => '0d 8h 9m 8s',  'type' => 'PROGRAM (RE)START', plugin_output => 'Program start', 'class' => 'INDETERMINATE' },
    { 'start' => '2010-01-09 00:00:00', end => '2010-01-09 14:11:33', 'duration' => '0d 14h 11m 33s',  'type' => 'HOST UP (HARD)',      plugin_output => 'n0_test_host_000 ...',        'class' => 'UP', 'in_downtime' => 0 },
    { 'start' => '2010-01-09 14:11:33', end => '2010-01-09 14:22:53', 'duration' => '0d 0h 11m 20s',   'type' => 'HOST DOWNTIME START', plugin_output => 'Start of scheduled downtime', 'class' => 'INDETERMINATE', 'in_downtime' => 1 },
    { 'start' => '2010-01-09 14:22:53', end => '2010-01-09 14:25:55', 'duration' => '0d 0h 3m 2s',     'type' => 'HOST DOWNTIME STOP',  plugin_output => 'End of scheduled downtime',   'class' => 'INDETERMINATE', 'in_downtime' => 0 },
    { 'start' => '2010-01-09 14:25:55', end => '2010-01-09 14:26:00', 'duration' => '0d 0h 0m 5s',  'type' => 'PROGRAM END', plugin_output => 'Normal program termination', 'class' => 'INDETERMINATE' },
    { 'start' => '2010-01-09 14:26:00', end => '2010-01-14 20:54:10', 'duration' => '5d 6h 28m 10s+',  'type' => 'PROGRAM (RE)START', plugin_output => 'Program start', 'class' => 'INDETERMINATE' },
];

#########################
my $ma = Monitoring::Availability->new(
    'verbose'                       => 0,
    'backtrack'                     => 4,
    'assumestateretention'          => 'yes',
    'assumeinitialstates'           => 'yes',
    'assumestatesduringnotrunning'  => 'no',
    'initialassumedhoststate'       => 'unspecified',
    'initialassumedservicestate'    => 'unspecified',
);
isa_ok($ma, 'Monitoring::Availability', 'create new Monitoring::Availability object');
my $result = $ma->calculate(
    'log_string'                    => $logs,
    'hosts'                         => ['n0_test_host_000'],
    'start'                         => 1262894050,
    'end'                           => 1263498850,
    'timeformat'                    => '%Y-%m-%d %H:%M:%S',
);

is_deeply($result, $expected, 'host with downtime') or diag("got:\n".Dumper($result)."\nbut expected:\n".Dumper($expected));
my $condensed_logs = $ma->get_condensed_logs();
# test will fail on windows because of a different used timezone
TestUtils::check_array_one_by_one($expected_condensed_log, $condensed_logs, 'condensed logs');

my $full_logs = $ma->get_full_logs();
# test will fail on windows because of a different used timezone
TestUtils::check_array_one_by_one($expected_full_log, $full_logs, 'full logs');

__DATA__
[1262962252] Nagios 3.2.0 starting... (PID=7873)
[1262991600] CURRENT HOST STATE: n0_test_host_000;OK;HARD;1;n0_test_host_000 ...
[1263042693] HOST DOWNTIME ALERT: n0_test_host_000;STARTED; Host has entered a period of scheduled downtime
[1263043373] HOST DOWNTIME ALERT: n0_test_host_000;STOPPED; Host has exited from a period of scheduled downtime
[1263043555] Caught SIGSEGV, shutting down...
[1263043560] Nagios 3.2.0 starting... (PID=22865)
