#!/usr/bin/env perl

#########################

use strict;
use Test::More tests => 3;
use Data::Dumper;

BEGIN {
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
            'time_up'          => 0,
            'time_down'        => 507250,
            'time_unreachable' => 0,

            'scheduled_time_up'             => 0,
            'scheduled_time_down'           => 0,
            'scheduled_time_unreachable'    => 0,
            'scheduled_time_indeterminate'  => 0,

            'time_indeterminate_nodata'     => 97550,
            'time_indeterminate_notrunning' => 0,
            'time_indeterminate_outside_timeperiod' => 0,
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
);
isa_ok($ma, 'Monitoring::Availability', 'create new Monitoring::Availability object');
my $result = $ma->calculate(
    'log_string'                    => $logs,
    'hosts'                         => ['n0_test_host_000'],
    'start'                         => 1262894050,
    'end'                           => 1263498850,
);
is_deeply($result, $expected, 'down host') or diag("got:\n".Dumper($result)."\nbut expected:\n".Dumper($expected));

__DATA__
[1262962252] Nagios 3.2.0 starting... (PID=7873)
[1262991600] CURRENT HOST STATE: n0_test_host_000;DOWN;HARD;1;n0_test_host_000 ...
