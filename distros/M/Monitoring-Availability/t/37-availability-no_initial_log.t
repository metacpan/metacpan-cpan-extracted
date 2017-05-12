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
    'hosts' => {},
    'services' => {
        'n0_test_host_000' => {
            'n0_test_random_04' => {
                'time_ok'           => 1000,
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

#########################
my $ma = Monitoring::Availability->new(
    'verbose'                       => 0,
    'backtrack'                     => 4,
    'assumestateretention'          => 'yes',
    'assumeinitialstates'           => 'yes',
    'assumestatesduringnotrunning'  => 'yes',
    'initialassumedhoststate'       => 'up',
    'initialassumedservicestate'    => 'ok',
);
isa_ok($ma, 'Monitoring::Availability', 'create new Monitoring::Availability object');
my $result = $ma->calculate(
    'log_string'                    => $logs,
    'services'                      => [{'host' => 'n0_test_host_000', 'service' => 'n0_test_random_04'}],
    'start'                         => 1262991000,
    'end'                           => 1262992000,
);
is_deeply($result, $expected, 'critical service') or diag("got:\n".Dumper($result)."\nbut expected:\n".Dumper($expected));

__DATA__
[1262991000] Nagios 3.2.0 starting... (PID=7873)
