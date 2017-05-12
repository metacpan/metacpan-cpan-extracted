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
my $expected = {
    'services' => {},
    'hosts' => {
        'mo' => {
            'time_up'          => 172800,
            'time_down'        => 0,
            'time_unreachable' => 0,

            'scheduled_time_up'             => 0,
            'scheduled_time_down'           => 0,
            'scheduled_time_unreachable'    => 0,
            'scheduled_time_indeterminate'  => 0,

            'time_indeterminate_nodata'     => 0,
            'time_indeterminate_notrunning' => 0,
            'time_indeterminate_outside_timeperiod' => 0,
        }
    }
};

#########################
my $ma = Monitoring::Availability->new(
    'verbose'                       => 0,
    'assumeinitialstates'           => 'yes',
    'initialassumedhoststate'       => 'up',
    'initialassumedservicestate'    => 'ok',
);
isa_ok($ma, 'Monitoring::Availability', 'create new Monitoring::Availability object');
my $result = $ma->calculate(
    'log_livestatus'                => [],
    'hosts'                         => ['mo'],
    'start'                         => 1334959200,
    'end'                           => 1335132000,
);
is_deeply($result, $expected, 'nologs host') or diag("got:\n".Dumper($result)."\nbut expected:\n".Dumper($expected));

my $logs    = $ma->get_full_logs();
my $explogs = [{
        'plugin_output' => 'First Host State Assumed (Faked Log Entry)',
        'duration'      => '2d 0h 0m 0s+',
        'class'         => 'UP',
        'type'          => 'HOST UP (HARD)',
        'end'           => 1335132000,
        'start'         => 1334959200
}];
is_deeply($logs, $explogs, 'nologs host logs') or diag("got:\n".Dumper($logs)."\nbut expected:\n".Dumper($explogs));
