#!/usr/bin/perl

use strict;
use warnings;
use POE;
use Test::More tests => 6;

BEGIN { use_ok( 'POE::Component::PreforkDispatch' ); }

POE::Session->create(
    inline_states => {
        _start => \&start,
        do_slow_task => \&task,
        do_slow_task_cb => \&task_cb,
        force_kill => \&force_kill,
    },
    heap => {
        do_requests => 5, # tests - 1
    },
);

$poe_kernel->run();

sub start {
    my ($kernel, $heap) = @_[KERNEL, HEAP];
    POE::Component::PreforkDispatch->create(
        max_forks => 4,
        pre_fork  => 2,
        talkback  => sub {},
    );
    foreach (1..$heap->{do_requests}) {
        $kernel->post(PreforkDispatch => 'new_request', {
            method      => 'do_slow_task',
            upon_result => 'do_slow_task_cb',
            params      => [ 'a value', $_, ],
        });
    }
    # Just in case we get an endless loop
    $kernel->delay('force_kill', 5);
}

sub task {
    my ($kernel, $heap, $from, $param1, $param2) = @_[KERNEL, HEAP, ARG0 .. $#_];

    # ... do something slow

    # Return hashref or arrayref
    return { success => 1 };
}

sub task_cb {
    my ($kernel, $heap, $request, $result) = @_[KERNEL, HEAP, ARG0, ARG1];

    ok($result->{success}, "Task " . $request->{params}[1] . " successful");

    if (++$heap->{successes} == $heap->{do_requests}) {
        exit;
    }
}

sub force_kill {
    my ($kernel, $heap) = @_[KERNEL, HEAP];
    print STDERR "Timeout; let's exit rather than endless loop\n";
    exit;
}
