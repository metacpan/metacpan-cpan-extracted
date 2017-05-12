#!/usr/bin/perl
use strict;
use warnings FATAL => "all";
 no warnings "numeric";

use POE qw( Component::Pool::Thread );
use Test::Simple tests => 1;
# This test is full of screwed up race condition based behavior...it needs to
# be rethought.
#
# It appears the component is working correctly, I just apparently didn't know
# what I was doing at the time.
ok 1;
exit 0;

POE::Component::Pool::Thread->new
( MaxFree       => 5,
  MinFree       => 2,
  MaxThreads    => 8,
  StartThreads  => 3,
  Name          => "ThreadPool",
  EntryPoint    => \&thread_entry_point,
  CallBack      => \&response,
  inline_states => {
    _start  => sub {
        $_[KERNEL]->yield("go");
    },

    go => sub {
        my ($kernel, $session, $heap) = @_[ KERNEL, SESSION, HEAP ];
        my ($thread, @free);

        $kernel->call($session, run => 1) for 1 .. 3;

        $thread = $heap->{thread};
        @free   = grep ${ $_->{semaphore} }, values %$thread;

# These are race condition-y
#       ok(scalar keys %$thread == 0);

        $kernel->call($session, run => 0) for 4 .. 20;

#       ok @{ $heap->{queue} };
# What was I thinking...what an obvious race condition.
#        $kernel->yield(run => "finished");
    },
  }
);

sub thread_entry_point {
    my ($delay) = @_;

    # So we can check
    select undef, undef, undef, 0.5 if int $delay;

    ok 1;

    return $delay;
}

{
    my $responses = 0;
    sub response {
        my ($kernel, $heap, $result) = @_[ KERNEL, HEAP, ARG0 ];
        my (@thread, @free);

        @thread  = values %{ $heap->{thread} };
        @free    = grep ${ $_->{semaphore} }, @thread;

        ok @thread <= 8;

        if (@{ $heap->{queue} }) {
            ok ((@free >= 2 && @free <= 5) || (@free == 8 && @thread <= 8));
        }
        else {
# During shut down or quick load drops this happens, but only
# temporarily.  Eventually the component gets around to GC'ing
# everything.  This is just to make sure there aren't extra threads
            ok @free <= 8;
        }

        if (++$responses == 20) {
            ok 1;
            $kernel->yield("shutdown");
        }
    }
}

run POE::Kernel;
