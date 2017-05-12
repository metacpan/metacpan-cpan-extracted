#!/usr/local/bin/perl

# Test derived from 14-session-ref-3.t

# Test creating a schedule giving to P::C::S a session alias (instead of a
# session object).


use strict;
use warnings;

use Test::More tests => 16;
use POE qw(Component::Schedule);
use DateTime::Set;

sub SESS_ALIAS { "session-arg-alias" }


POE::Session->create(
    inline_states => {
        _start => sub {
	    $poe_kernel->alias_set(SESS_ALIAS);
            pass "_start";
            diag scalar localtime;
            $_[HEAP]{count} = 3;
            $poe_kernel->yield('create_schedule');
        },
        create_schedule => sub {
            cmp_ok $_[HEAP]{count}, '>', 0, "Create schedule ".$_[HEAP]{count};
            $_[HEAP]{sched} = POE::Component::Schedule->add(
                SESS_ALIAS, Tick => DateTime::Set->from_recurrence(
                    # Infinite set
                    after => DateTime->now,
                    recurrence => sub {
                        return $_[0]->add( seconds => 1 )
                    },
                ),
                [ 2 ], # Tick counter storage
            );
        },

        Tick => sub {
            cmp_ok($_[ARG0]->[0], '>', 0, 'Tick '.$_[ARG0]->[0].' > 0');
            diag scalar localtime;
            if (--$_[ARG0]->[0] == 0) {
                pass "Kill schedule";
                delete $_[HEAP]{sched};
                $poe_kernel->yield('create_schedule') if --$_[HEAP]{count} > 0;
            }
        },

        _stop => sub {
            pass "_stop";
            is $_[HEAP]{count}, 0, "count is 0";
        },
    },
);

POE::Kernel->run();

pass "Stopped";
