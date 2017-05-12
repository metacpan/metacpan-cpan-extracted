#!/usr/bin/env perl

#########################

use strict;
use Test::More tests => 60;
use Data::Dumper;
use File::Temp qw/ tempfile tempdir /;

use_ok('Monitoring::Availability::Logs');

#########################

my $expected = [
    { 'time' => '1260711580', 'type' => 'Local time is Sun Dec 13 14:39:40 CET 2009' },
    { 'time' => '1260711580', 'type' => 'Nagios 3.0.6 starting... (PID=12480)', 'proc_start' => 1 },
    { 'time' => '1260711581', 'type' => 'Finished daemonizing... (New PID=12484)' },
    { 'time' => '1260715790', 'type' => 'Error' },
    { 'time' => '1260715801', 'type' => 'Successfully shutdown... (PID=12502)' },
    { 'time' => '1260716221', 'type' => 'Lockfile \'/opt/projects/nagios/n1/var/nagios3.pid\' looks like its already held by another instance of Nagios (PID 13226).  Bailing out...', 'proc_start' => -1 },
    { 'time' => '1260722815', 'type' => 'Warning' },
    { 'time' => '1260725492', 'type' => 'Warning' },
    { 'time' => '1260725492', 'type' => 'Warning' },
    { 'time' => '1260971246', 'type' => 'PROGRAM_RESTART event encountered, restarting...', 'proc_start' => 2 },
    { 'time' => '1261050819', 'type' => 'PASSIVE HOST CHECK' },
    { 'time' => '1261685289', 'type' => 'SERVICE NOTIFICATION' },
    { 'time' => '1261686379', 'type' => 'SERVICE FLAPPING ALERT' },
    { 'time' => '1261686484', 'type' => 'SERVICE ALERT', 'host_name' => 'i0test_host_132', 'service_description' => 'i0test_random_18', 'state' => 2, 'hard' => 1, 'plugin_output' => 'mo CRITICAL: random servicecheck critical' },
    { 'time' => '1261687372', 'type' => 'HOST ALERT', 'host_name' => 'i0test_host_198', 'state' => 1, 'hard' => 1, 'plugin_output' => 'mo DOWN: random hostcheck: parent host down' },
    { 'time' => '1261687372', 'type' => 'HOST NOTIFICATION' },
    { 'time' => '1261687373', 'type' => 'HOST FLAPPING ALERT' },
    { 'time' => '1262850812', 'type' => 'Caught SIGSEGV, shutting down...', 'proc_start' => 0 },
    { 'time' => '1262850822', 'type' => 'HOST DOWNTIME ALERT', 'host_name' => 'localhost', 'start' => 1 },
    { 'time' => '1262850822', 'type' => 'SERVICE DOWNTIME ALERT', 'host_name' => 'localhost', 'service_description' => 'test', 'start' => 1 },
    { 'time' => '1263042133', 'type' => 'EXTERNAL COMMAND' },
    { 'time' => '1263423600', 'type' => 'CURRENT HOST STATE', 'host_name' => 'i0test_router_19', 'state' => 0, 'hard' => 1, 'plugin_output' => 'mo OK: random hostcheck ok' },
    { 'time' => '1263423600', 'type' => 'CURRENT SERVICE STATE', 'host_name' => 'i0test_host_199', 'service_description' => 'i0test_warning_18', 'state' => 1, 'hard' => 1, 'plugin_output' => 'mo WARNING: warning servicecheck' },
    { 'time' => '1263423600', 'type' => 'LOG ROTATION' },
    { 'time' => '1263457861', 'type' => 'Auto-save of retention data completed successfully.' },
    { 'time' => '1263458022', 'type' => 'Caught SIGTERM, shutting down...', 'proc_start' => 0 },
    { 'time' => '1263648166', 'type' => 'LOG VERSION' },
];

my $mal = Monitoring::Availability::Logs->new();
isa_ok($mal, 'Monitoring::Availability::Logs', 'create new Monitoring::Availability::Logs object');

####################################
# try logs, line by line
my $x = 0;
my $logs;
while(my $line = <DATA>) {
    $logs .= $line;
    $mal->{'logs'} = [];
    my $rt = $mal->_store_logs_from_string($line);
    is($rt, 1, '_store_logs_from_string rc') or fail_out($x, $line, $mal);
    is_deeply($mal->{'logs'}->[0], $expected->[$x], 'reading logs from string') or fail_out($x, $line, $mal);
    $x++;
}

####################################
# write logs to temp file and load it
my($fh,$filename) = tempfile(CLEANUP => 1);
print $fh $logs;
close($fh);

$mal->{'logs'} = [];
my $rt = $mal->_store_logs_from_file($filename);
is($rt, 1, '_store_logs_from_file rc');
is_deeply($mal->{'logs'}, $expected, 'reading logs from file');

####################################
# write logs to temp dir and load it
my $dir = tempdir( CLEANUP => 1 );
open(my $logfile, '>', $dir.'/monitoring.log') or die('cannot write to '.$dir.'/monitoring.log: '.$!);
print $logfile $logs;
close($logfile);

$mal->{'logs'} = [];
$rt = $mal->_store_logs_from_dir($dir);
is($rt, 1, '_store_logs_from_dir rc');
is_deeply($mal->{'logs'}, $expected, 'reading logs from dir');



####################################
# fail and die with debug output
sub fail_out {
    my $x    = shift;
    my $line = shift;
    my $mal  = shift;
    diag('line: '.Dumper($line));
    diag('got : '.Dumper($mal->{'logs'}->[0]));
    diag('exp : '.Dumper($expected->[$x]));
    BAIL_OUT('failed');
}


__DATA__
[1260711580] Local time is Sun Dec 13 14:39:40 CET 2009: 39:40 CET 2009
[1260711580] Nagios 3.0.6 starting... (PID=12480)
[1260711581] Finished daemonizing... (New PID=12484)
[1260715790] Error: Unable to create temp file for writing status data!
[1260715801] Successfully shutdown... (PID=12502)
[1260716221] Lockfile '/opt/projects/nagios/n1/var/nagios3.pid' looks like its already held by another instance of Nagios (PID 13226).  Bailing out...
[1260722815] Warning: The check of host 'test_host_020' looks like it was orphaned (results never came back).  I'm scheduling an immediate check of the host...
[1260725492] Warning: Check result queue contained results for host 'test_host_105', but the host could not be found!  Perhaps you forgot to define the host in your config files?
[1260725492] Warning: Check result queue contained results for service 'test_ok_04' on host 'test_host_131', but the service could not be found!  Perhaps you forgot to define the service in your config files?
[1260971246] PROGRAM_RESTART event encountered, restarting...
[1261050819] PASSIVE HOST CHECK: n1_test_router_00;0;blah blah blah
[1261685289] SERVICE NOTIFICATION: test_contact;i0test_host_180;i0test_random_18;OK;notify-service;mo REVOVERED: random servicecheck recovered
[1261686379] SERVICE FLAPPING ALERT: i0test_host_135;i0test_flap_01;STARTED; Service appears to have started flapping (24.2% change >= 20.0% threshold)
[1261686484] SERVICE ALERT: i0test_host_132;i0test_random_18;CRITICAL;HARD;1;mo CRITICAL: random servicecheck critical
[1261687372] HOST ALERT: i0test_host_198;DOWN;HARD;1;mo DOWN: random hostcheck: parent host down
[1261687372] HOST NOTIFICATION: test_contact;i0test_host_198;DOWN;notify-host;mo DOWN: random hostcheck: parent host down
[1261687373] HOST FLAPPING ALERT: i0test_host_198;STARTED; Host appears to have started flapping (20.3% change > 20.0% threshold)
[1262850812] Caught SIGSEGV, shutting down...
[1262850822] HOST DOWNTIME ALERT: localhost;STARTED; Host has entered a period of scheduled downtime
[1262850822] SERVICE DOWNTIME ALERT: localhost;test;STARTED; Service has entered a period of scheduled downtime
[1263042133] EXTERNAL COMMAND: ENABLE_NOTIFICATIONS;
[1263423600] CURRENT HOST STATE: i0test_router_19;UP;HARD;1;mo OK: random hostcheck ok
[1263423600] CURRENT SERVICE STATE: i0test_host_199;i0test_warning_18;WARNING;HARD;3;mo WARNING: warning servicecheck
[1263423600] LOG ROTATION: DAILY: DAILY
[1263457861] Auto-save of retention data completed successfully.
[1263458022] Caught SIGTERM, shutting down...
[1263648166] LOG VERSION: 2.0
