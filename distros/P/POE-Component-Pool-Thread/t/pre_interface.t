#!/usr/bin/perl

use strict;
use warnings FATAL => "all";

our $TOTAL_JOBS;
BEGIN { $TOTAL_JOBS = 4 }
use POE qw( Component::Pool::Thread );
use Test::Simple tests => 2*$TOTAL_JOBS;

POE::Component::Pool::Thread->new
( MaxFree       => 5,
  MinFree       => 2,
  MaxThreads    => 10,
  StartThreads  => 5,
  Name          => "ThreadPool",
  EntryPoint    => \&thread_entry_point,
  CallBack      => \&response,
  inline_states => {
    _start  => sub {
        $_[KERNEL]->yield(loop => 1),
    },

    loop    => sub {
        my ($kernel, $i) = @_[ KERNEL, ARG0 ];

        $kernel->yield(run => $i);

        if ($i < $TOTAL_JOBS) {
            $kernel->yield(loop => $i + 1);

            # Simulate variable loads
            select undef, undef, undef, rand 0.2;
        }
    },
  }
);

sub thread_entry_point {
    my $point = shift;
    
    # Simulate tasks that take time and block
    select undef, undef, undef, rand 0.5;

    ok(1, "thread_entry_point $point");

    return $point;
}

{
    my $responses = 0;

    sub response {
        my ($kernel, $result) = @_[ KERNEL, ARG0 ];

        ok(1, "response $result\n");

        if (++$responses == $TOTAL_JOBS) {
            $kernel->yield("shutdown");
        }
    }
}

run POE::Kernel;
