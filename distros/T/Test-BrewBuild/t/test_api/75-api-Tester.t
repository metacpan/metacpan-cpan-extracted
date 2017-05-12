#!/usr/bin/perl
use strict;
use warnings;

use Capture::Tiny qw(capture_stdout);
use Test::BrewBuild::Tester;
use Test::More;

if (! $ENV{BBDEV_TESTING}){
    plan skip_all => "developer tests only";
    exit;
}

my $mod = 'Test::BrewBuild::Tester';

{ # default
    my $t = $mod->new;

    is ($t->status, 0, "status returns 0 if tester not running");

    my $start = capture_stdout {
            $t->start;
    };

    like (
        $start,
        qr/Started .*0\.0\.0\.0 .*7800/,
        "proper ip/port for default start"
    );

    is ($t->status, 1, "status returns 1 if tester is running");

    my $stat = `netstat -na`;

    like ($stat, qr/0\.0\.0\.0:7800/, "netstat -na returns ok results");

    my $stop = capture_stdout {
            $t->stop;
    };

    like (
        $stop,
        qr/Stopping.*PID \d+/,
        "stopping works",
    );
}
{ # ip
    my $t = $mod->new;

    $t->ip('127.0.0.1');

    my $start = capture_stdout {
            $t->start;
    };

    like (
        $start,
        qr/Started .*127\.0\.0\.1 .*7800/,
        "proper ip/port for ip() and default port"
    );

    my $stop = capture_stdout {
            $t->stop;
    };

    like (
        $stop,
        qr/Stopping.*PID \d+/,
        "stopping works",
    );
}
{ # port
    my $t = $mod->new;

    $t->port(9999);

    my $start = capture_stdout {
            $t->start;
    };

    like (
        $start,
        qr/Started .*0\.0\.0\.0 .*9999/,
        "proper ip/port for port() and default ip"
    );

    my $stop = capture_stdout {
            $t->stop;
    };

    like (
        $stop,
        qr/Stopping.*PID \d+/,
        "stopping works",
    );
}
{ # port and ip
    my $t = $mod->new;

    $t->ip('127.0.0.1');
    $t->port(9999);

    my $start = capture_stdout {
            $t->start;
    };

    like (
        $start,
        qr/Started .*127\.0\.0\.1 .*9999/,
        "proper ip/port for port() and ip()"
    );

    my $stop = capture_stdout {
            $t->stop;
    };

    like (
        $stop,
        qr/Stopping.*PID \d+/,
        "stopping works",
    );
}

done_testing();

