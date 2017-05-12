package TimeShell;

use lib '../lib';
use strict;
use base 'SSH::RPC::Shell';
use Time::HiRes;

sub run_time {
    my @time = localtime(time());
    return {
        status      => 200,
        response    => join(":", $time[2], $time[1], $time[0]),
        };
}

sub run_hiResTime {
    my ($seconds, $microseconds) = Time::HiRes::gettimeofday();
    my @time = localtime($seconds);
    return {
        status      => 200,
        response    => [ $time[2], $time[1], $time[0], $microseconds ],
        };
}

1;

