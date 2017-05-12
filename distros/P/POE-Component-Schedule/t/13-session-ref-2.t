#!/usr/local/bin/perl

use strict;
use warnings;

use Test::More tests => 6;
use POE qw(Component::Schedule);
use DateTime::Set;

POE::Session->create(
    inline_states => {
        _start => sub {
            pass "_start";
            diag scalar localtime;
            $_[HEAP]{count} = 2;
            $_[HEAP]{sched} = POE::Component::Schedule->add(
                $_[SESSION], Tick => DateTime::Set->from_recurrence(
                    # Infinite set
                    after => DateTime->now,
                    recurrence => sub {
                        return $_[0]->add( seconds => 1 )
                    },
                ),
            );
        },

        Tick => sub {
            cmp_ok($_[HEAP]{count}, '>', 0, 'Tick '.$_[HEAP]{count}.' > 0');
            diag scalar localtime;
            if (--$_[HEAP]{count} == 0) {
                pass "Kill schedule";
                # Once we delete the last schedule, we expect the session to stop
                delete $_[HEAP]{sched};
            }
        },

        _stop => sub {
            pass "_stop";
        },
    },
);

POE::Kernel->run();

pass "Stopped";
