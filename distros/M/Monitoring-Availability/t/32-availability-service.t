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
        plan tests => 18;
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
            'n0_test_pending_01' => {
                'time_ok'           => 0,
                'time_warning'      => 0,
                'time_unknown'      => 20,
                'time_critical'     => 647,

                'scheduled_time_ok'             => 0,
                'scheduled_time_warning'        => 0,
                'scheduled_time_unknown'        => 0,
                'scheduled_time_critical'       => 633,
                'scheduled_time_indeterminate'  => 55,

                'time_indeterminate_nodata'     => 85733,
                'time_indeterminate_notrunning' => 0,
                'time_indeterminate_outside_timeperiod' => 0,
            }
        }
    }
};

my $expected_condensed_log = [
    { 'start' => '2010-01-21 23:12:10', end => '2010-01-21 23:13:05', 'duration' => '0d 0h 0m 55s',  'type' => 'SERVICE DOWNTIME START', plugin_output => 'Start of scheduled downtime', 'class' => 'INDETERMINATE', 'in_downtime' => 1 },
    { 'start' => '2010-01-21 23:13:05', end => '2010-01-21 23:13:37', 'duration' => '0d 0h 0m 32s',  'type' => 'SERVICE DOWNTIME END', plugin_output => 'End of scheduled downtime', 'class' => 'INDETERMINATE', 'in_downtime' => 0 },
    { 'start' => '2010-01-21 23:14:00', end => '2010-01-21 23:14:20', 'duration' => '0d 0h 0m 20s',  'type' => 'SERVICE UNKNOWN (HARD)', plugin_output => 'unknown', 'class' => 'UNKNOWN', 'in_downtime' => 0 },
    { 'start' => '2010-01-21 23:14:20', end => '2010-01-21 23:14:34', 'duration' => '0d 0h 0m 14s',  'type' => 'SERVICE CRITICAL (HARD)', plugin_output => 'critical', 'class' => 'CRITICAL', 'in_downtime' => 0 },
    { 'start' => '2010-01-21 23:14:34', end => '2010-01-21 23:25:07', 'duration' => '0d 0h 10m 33s+','type' => 'HOST DOWNTIME START', plugin_output => 'Start of scheduled downtime', 'class' => 'INDETERMINATE', 'in_downtime' => 1 },
];

my $expected_full_log = [
    { 'start' => '2010-01-21 23:05:15', end => '2010-01-21 23:12:10', 'duration' => '0d 0h 6m 55s',  'type' => 'PROGRAM (RE)START', plugin_output => 'Program start', 'class' => 'INDETERMINATE' },
    { 'start' => '2010-01-21 23:12:10', end => '2010-01-21 23:13:05', 'duration' => '0d 0h 0m 55s',  'type' => 'SERVICE DOWNTIME START', plugin_output => 'Start of scheduled downtime', 'class' => 'INDETERMINATE', 'in_downtime' => 1 },
    { 'start' => '2010-01-21 23:13:05', end => '2010-01-21 23:13:37', 'duration' => '0d 0h 0m 32s',  'type' => 'SERVICE DOWNTIME END', plugin_output => 'End of scheduled downtime', 'class' => 'INDETERMINATE', 'in_downtime' => 0},
    { 'start' => '2010-01-21 23:13:37', end => '2010-01-21 23:13:38', 'duration' => '0d 0h 0m 1s',   'type' => 'PROGRAM (RE)START', plugin_output => 'Program restart', 'class' => 'INDETERMINATE' },
    { 'start' => '2010-01-21 23:13:38', end => '2010-01-21 23:14:00', 'duration' => '0d 0h 0m 22s',  'type' => 'PROGRAM (RE)START', plugin_output => 'Program start', 'class' => 'INDETERMINATE' },
    { 'start' => '2010-01-21 23:14:00', end => '2010-01-21 23:14:20', 'duration' => '0d 0h 0m 20s',  'type' => 'SERVICE UNKNOWN (HARD)', plugin_output => 'unknown', 'class' => 'UNKNOWN', 'in_downtime' => 0 },
    { 'start' => '2010-01-21 23:14:20', end => '2010-01-21 23:14:34', 'duration' => '0d 0h 0m 14s',  'type' => 'SERVICE CRITICAL (HARD)', plugin_output => 'critical', 'class' => 'CRITICAL', 'in_downtime' => 0 },
    { 'start' => '2010-01-21 23:14:34', end => '2010-01-21 23:25:07', 'duration' => '0d 0h 10m 33s+','type' => 'HOST DOWNTIME START', plugin_output => 'Start of scheduled downtime', 'class' => 'INDETERMINATE', 'in_downtime' => 1 },
];

#########################
# avail.cgi?host=n0_test_host_000&service=n0_test_pending_01&t1=1264026307&t2=1264112707&backtrack=4&assumestateretention=yes&assumeinitialstates=yes&assumestatesduringnotrunning=yes&initialassumedhoststate=0&initialassumedservicestate=0&show_log_entries&showscheduleddowntime=yes
my $ma = Monitoring::Availability->new(
    'verbose'                       => 0,
    'backtrack'                     => 4,
    'assumestateretention'          => 'yes',
    'assumeinitialstates'           => 'yes',
    'assumestatesduringnotrunning'  => 'yes',
    'initialassumedhoststate'       => 'unspecified',
    'initialassumedservicestate'    => 'unspecified',
    'showscheduleddowntime'         => 'yes',
    'timeformat'                    => '%Y-%m-%d %H:%M:%S',
);
isa_ok($ma, 'Monitoring::Availability', 'create new Monitoring::Availability object');
my $result = $ma->calculate(
    'log_string'                    => $logs,
    'services'                      => [{'host' => 'n0_test_host_000', 'service' => 'n0_test_pending_01'}],
    'start'                         => 1264026307,
    'end'                           => 1264112707,
);
is_deeply($result, $expected, 'service availability') or diag("got:\n".Dumper($result)."\nbut expected:\n".Dumper($expected));

my $condensed_logs = $ma->get_condensed_logs();
# test will fail on windows because of a different used timezone
TestUtils::check_array_one_by_one($expected_condensed_log, $condensed_logs, 'condensed logs');

my $full_logs = $ma->get_full_logs();
# test will fail on windows because of a different used timezone
TestUtils::check_array_one_by_one($expected_full_log, $full_logs, 'full logs');

__DATA__
[1264111515] Nagios 3.2.0 starting... (PID=31189)
[1264111515] Local time is Thu Jan 21 23:05:15 CET 2010
[1264111515] LOG VERSION: 2.0
[1264111515] livestatus: Setting max number of cached log messages to 0
[1264111515] livestatus: Version 1.1.2rc1 initializing. Socket path: '/tmp/live.sock'
[1264111515] livestatus: Created UNIX control socket at /tmp/live.sock
[1264111515] livestatus: Opened UNIX socket /tmp/live.sock
[1264111515] livestatus: successfully finished initialization
[1264111515] Event broker module '/opt/projects/git/check_mk/livestatus/src/livestatus.o' initialized successfully.
[1264111516] Finished daemonizing... (New PID=31195)
[1264111516] livestatus: Entering main loop, listening on UNIX socket. PID is 31195
[1264111516] livestatus: Starting 10 client threads
[1264111516] SERVICE DOWNTIME ALERT: n0_test_host_004;n0_test_critical_18;STARTED; Service has entered a period of scheduled downtime
[1264111555] EXTERNAL COMMAND: PROCESS_SERVICE_CHECK_RESULT;n0_test_host_000;n0_test_pending_01;0;ok|
[1264111556] PASSIVE SERVICE CHECK: n0_test_host_000;n0_test_pending_01;0;ok
[1264111929] EXTERNAL COMMAND: SCHEDULE_SVC_DOWNTIME;n0_test_host_000;n0_test_pending_01;1264111923;1264119123;1;0;0;thrukadmin;downtime
[1264111930] SERVICE DOWNTIME ALERT: n0_test_host_000;n0_test_pending_01;STARTED; Service has entered a period of scheduled downtime
[1264111944] EXTERNAL COMMAND: PROCESS_SERVICE_CHECK_RESULT;n0_test_host_000;n0_test_pending_01;1;warn|
[1264111946] PASSIVE SERVICE CHECK: n0_test_host_000;n0_test_pending_01;1;warn
[1264111946] SERVICE ALERT: n0_test_host_000;n0_test_pending_01;WARNING;SOFT;1;warn
[1264111967] EXTERNAL COMMAND: DEL_SVC_COMMENT;730
[1264111985] EXTERNAL COMMAND: DEL_SVC_DOWNTIME;551
[1264111985] SERVICE DOWNTIME ALERT: n0_test_host_000;n0_test_pending_01;CANCELLED; Scheduled downtime for service has been cancelled.
[1264112005] EXTERNAL COMMAND: PROCESS_SERVICE_CHECK_RESULT;n0_test_host_000;n0_test_pending_01;3;unknown|
[1264112006] PASSIVE SERVICE CHECK: n0_test_host_000;n0_test_pending_01;3;unknown
[1264112006] SERVICE ALERT: n0_test_host_000;n0_test_pending_01;UNKNOWN;SOFT;2;unknown
[1264112016] EXTERNAL COMMAND: RESTART_PROCESS;
[1264112017] PROGRAM_RESTART event encountered, restarting...
[1264112017] livestatus: deinitializing
[1264112017] livestatus: Waiting for main to terminate...
[1264112018] livestatus: Socket thread has terminated
[1264112018] livestatus: error: Client connection terminated while request still incomplete
[1264112018] livestatus: Waiting for client threads to terminate...
[1264112018] livestatus: Main thread + 10 client threads have finished
[1264112018] Event broker module '/opt/projects/git/check_mk/livestatus/src/livestatus.o' deinitialized successfully.
[1264112018] Nagios 3.2.0 starting... (PID=31195)
[1264112018] Local time is Thu Jan 21 23:13:38 CET 2010
[1264112018] LOG VERSION: 2.0
[1264112018] livestatus: Setting max number of cached log messages to 0
[1264112018] livestatus: Version 1.1.2rc1 initializing. Socket path: '/tmp/live.sock'
[1264112018] livestatus: Created UNIX control socket at /tmp/live.sock
[1264112018] livestatus: Opened UNIX socket /tmp/live.sock
[1264112018] livestatus: successfully finished initialization
[1264112018] Event broker module '/opt/projects/git/check_mk/livestatus/src/livestatus.o' initialized successfully.
[1264112019] livestatus: Starting 10 client threads
[1264112019] livestatus: Entering main loop, listening on UNIX socket. PID is 31195
[1264112020] SERVICE DOWNTIME ALERT: n0_test_host_004;n0_test_critical_18;STARTED; Service has entered a period of scheduled downtime
[1264112036] EXTERNAL COMMAND: PROCESS_SERVICE_CHECK_RESULT;n0_test_host_000;n0_test_pending_01;3;unknown|
[1264112040] PASSIVE SERVICE CHECK: n0_test_host_000;n0_test_pending_01;3;unknown
[1264112040] SERVICE ALERT: n0_test_host_000;n0_test_pending_01;UNKNOWN;HARD;3;unknown
[1264112040] SERVICE NOTIFICATION: test_contact;n0_test_host_000;n0_test_pending_01;UNKNOWN;notify-service;unknown
[1264112053] EXTERNAL COMMAND: PROCESS_SERVICE_CHECK_RESULT;n0_test_host_000;n0_test_pending_01;2;critical|
[1264112060] PASSIVE SERVICE CHECK: n0_test_host_000;n0_test_pending_01;2;critical
[1264112060] SERVICE ALERT: n0_test_host_000;n0_test_pending_01;CRITICAL;HARD;3;critical
[1264112060] SERVICE NOTIFICATION: test_contact;n0_test_host_000;n0_test_pending_01;CRITICAL;notify-service;critical
[1264112074] EXTERNAL COMMAND: SCHEDULE_HOST_DOWNTIME;n0_test_host_000;1264112067;1264119267;1;0;0;thrukadmin;downtime
[1264112074] HOST DOWNTIME ALERT: n0_test_host_000;STARTED; Host has entered a period of scheduled downtime
