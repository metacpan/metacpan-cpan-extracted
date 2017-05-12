#!/usr/local/bin/perl

use strict;
use warnings;

use Test::More tests => 6;
use POE qw(Component::Schedule);
use DateTime::Set;

# The only events in this session are the ones generated be PoCo::Schedule
# So we verify that the session refcount is automatically increased/decreased
# when a schedule is created/destroyed.

POE::Session->create(
    inline_states => {
        _start => sub {
            pass "_start";
            diag scalar localtime;
            $_[HEAP]{sched} = POE::Component::Schedule->add(
                $_[SESSION], Tick => DateTime::Set->from_recurrence(
                    start      => DateTime->now->truncate(to => 'second'),
                    # When there is no more event in the iterator, the schedule
                    # will be deleted, so the session ref count will be decreased
                    # so the session will end.
                    before     => DateTime->now->add(seconds => 3)->truncate(to => 'second'),
                    recurrence => sub {
                        return $_[0]->add( seconds => 1 )
                    },
                ),
            );
        },

        Tick => sub {
            pass "Tick";
            diag scalar localtime;
        },

        _stop => sub {
            pass "_stop";
            # The schedule has automatically been removed as there is no more
            # events in the iterator
            # We check that deleting the object does not break
            $_[HEAP]{sched}->delete;
            # Also garbage collection should
            delete $_[HEAP]{sched};
        },
    },
);

POE::Kernel->run();

pass "Stopped";
