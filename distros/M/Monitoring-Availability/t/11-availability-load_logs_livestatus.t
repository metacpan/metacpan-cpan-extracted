#!/usr/bin/env perl

#########################

use strict;
use Test::More tests => 4;
use Data::Dumper;

use_ok('Monitoring::Availability::Logs');

#########################

my $livestatus_logs= [
    { 'time' => '1263423600', 'type' => 'CURRENT HOST STATE', 'options' => 'i0test_router_19;UP;HARD;1;mo OK: random hostcheck ok', 'host_name' => 'i0test_router_19', 'service_description' => '', 'plugin_output' => 'mo OK: random hostcheck ok', 'state' => '0', 'class' => '6', },
    { 'time' => '1263423600', 'type' => 'CURRENT SERVICE STATE', 'service_description' => 'i0test_warning_18', 'plugin_output' => 'mo WARNING: warning servicecheck', 'options' => 'i0test_host_199;i0test_warning_18;WARNING;HARD;3;mo WARNING: warning servicecheck', 'state' => '1', 'host_name' => 'i0test_host_199', 'class' => '6', },
    { 'time' => '1261184172', 'type' => 'Caught SIGHUP, restarting...', 'options' => '', 'class' => '2', 'state' => '0' },
    { 'time' => '1263650899', 'type' => 'Caught SIGTERM, shutting down...', 'options' => '', 'class' => '2', 'state' => '0' },
    { 'time' => '1261687372', 'type' => 'HOST ALERT', 'options' => 'i0test_host_198;DOWN;HARD;1;mo DOWN: random hostcheck: parent host down', 'service_description' => '', 'plugin_output' => 'mo DOWN: random hostcheck: parent host down', 'state' => '1', 'host_name' => 'i0test_host_198', 'class' => '1', },
    { 'time' => '1262850822', 'type' => 'HOST DOWNTIME ALERT', 'options' => 'localhost;STARTED; Host has entered a period of scheduled downtime', 'host_name' => 'localhost', 'class' => '1', 'state' => '0' },
    { 'time' => '1261386470', 'type' => 'Nagios 3.0.6 starting... (PID=10056)', 'options' => '', 'class' => '2', 'state' => '0' },
    { 'time' => '1261686484', 'type' => 'SERVICE ALERT', 'options' => 'i0test_host_132;i0test_random_18;CRITICAL;HARD;1;mo CRITICAL: random servicecheck critical', 'service_description' => 'i0test_random_18', 'plugin_output' => 'mo CRITICAL: random servicecheck critical', 'state' => '2', 'host_name' => 'i0test_host_132', 'class' => '1', },
    { 'time' => '1262850822', 'type' => 'SERVICE DOWNTIME ALERT', 'options' => 'localhost;test;STARTED; Service has entered a period of scheduled downtime', 'service_description' => 'test', 'host_name' => 'localhost', 'class' => '1', 'state' => '0' },
    { 'time' => '1261686379', 'type' => 'SERVICE FLAPPING ALERT', 'options' => 'i0test_host_135;i0test_flap_01;STARTED; Service appears to have started flapping (24.2% change >= 20.0% threshold)', 'service_description' => 'i0test_flap_01', 'host_name' => 'i0test_host_135', 'class' => '1', 'state' => '0' },
    { 'time' => '1261685289', 'type' => 'SERVICE NOTIFICATION', 'options' => 'test_contact;i0test_host_180;i0test_random_18;OK;notify-service;mo REVOVERED: random servicecheck recovered', 'service_description' => 'i0test_random_18', 'plugin_output' => 'mo REVOVERED: random servicecheck recovered', 'state' => '0', 'host_name' => 'i0test_host_180', 'class' => '3', },
];

my $expected = [
    {'plugin_output' => 'mo OK: random hostcheck ok','service_description' => '','options' => 'i0test_router_19;UP;HARD;1;mo OK: random hostcheck ok','time' => '1263423600','state' => 0,'host_name' => 'i0test_router_19','type' => 'CURRENT HOST STATE','class' => '6','hard' => 1},
    {'plugin_output' => 'mo WARNING: warning servicecheck','service_description' => 'i0test_warning_18','options' => 'i0test_host_199;i0test_warning_18;WARNING;HARD;3;mo WARNING: warning servicecheck','time' => '1263423600','state' => 1,'host_name' => 'i0test_host_199','type' => 'CURRENT SERVICE STATE','class' => '6','hard' => 1},
    {'options' => '','time' => '1261184172','class' => '2','type' => 'Caught SIGHUP, restarting...','proc_start' => 2,'state' => '0'},
    {'options' => '','time' => '1263650899','class' => '2','type' => 'Caught SIGTERM, shutting down...','proc_start' => 0,'state' => '0'},
    {'plugin_output' => 'mo DOWN: random hostcheck: parent host down','service_description' => '','options' => 'i0test_host_198;DOWN;HARD;1;mo DOWN: random hostcheck: parent host down','time' => '1261687372','state' => 1,'host_name' => 'i0test_host_198','type' => 'HOST ALERT','class' => '1','hard' => 1},
    {'options' => 'localhost;STARTED; Host has entered a period of scheduled downtime','time' => '1262850822','host_name' => 'localhost','class' => '1','type' => 'HOST DOWNTIME ALERT','start' => 1,'state' => '0'},
    {'options' => '','time' => '1261386470','class' => '2','type' => 'Nagios 3.0.6 starting... (PID=10056)','proc_start' => 1,'state' => '0'},
    {'plugin_output' => 'mo CRITICAL: random servicecheck critical','service_description' => 'i0test_random_18','options' => 'i0test_host_132;i0test_random_18;CRITICAL;HARD;1;mo CRITICAL: random servicecheck critical','time' => '1261686484','state' => 2,'host_name' => 'i0test_host_132','type' => 'SERVICE ALERT','class' => '1','hard' => 1},
    {'service_description' => 'test','options' => 'localhost;test;STARTED; Service has entered a period of scheduled downtime','time' => '1262850822','state' => '0','host_name' => 'localhost','type' => 'SERVICE DOWNTIME ALERT','class' => '1','start' => 1},
    {'service_description' => 'i0test_flap_01','options' => 'i0test_host_135;i0test_flap_01;STARTED; Service appears to have started flapping (24.2% change >= 20.0% threshold)','time' => '1261686379','host_name' => 'i0test_host_135','class' => '1','type' => 'SERVICE FLAPPING ALERT','state' => '0'},
    {'plugin_output' => 'mo REVOVERED: random servicecheck recovered','service_description' => 'i0test_random_18','options' => 'test_contact;i0test_host_180;i0test_random_18;OK;notify-service;mo REVOVERED: random servicecheck recovered','time' => '1261685289','state' => '0','host_name' => 'i0test_host_180','type' => 'SERVICE NOTIFICATION','class' => '3'}
];

my $mal = Monitoring::Availability::Logs->new();
isa_ok($mal, 'Monitoring::Availability::Logs', 'create new Monitoring::Availability::Logs object');
my $rc = $mal->_store_logs_from_livestatus($livestatus_logs);
is($rc, 1, '_store_logs_from_livestatus rc');
is_deeply($mal->{'logs'}, $expected, 'sample 1 result');
