use strict;
use warnings;

use Test::More tests => 13;

use POE;
use POE::Component::Schedule;
use DateTime;
use DateTime::Set;


my $max = 2;

POE::Session->create(
    inline_states => {
        _start => sub {
            pass "_start";
            $_[HEAP]{count} = $max;
            $_[HEAP]{sched} = POE::Component::Schedule->add(
                $_[SESSION] => Tick => DateTime::Set->from_recurrence(
                        after      => DateTime->now->add( seconds => 1),
                        recurrence => sub {
                            return $_[0]->truncate( to => 'second' )->add( seconds => 1 )
                        },
                    ),
                'my_ticket', 1, 2,
            );
        },
        Tick => sub {
            pass "Tick " . --$_[HEAP]{count};
            diag scalar localtime;
            is($#_ - ARG0, 2, 'arg count');
            is($_[ARG0], 'my_ticket', "ARG0");
            is($_[ARG1], 1, "ARG1");
            is($_[ARG2], 2, "ARG2");
            if ($_[HEAP]{count} == 0) {
                diag "delete schedule";
                $_[HEAP]{sched}->delete;
                delete $_[HEAP]{sched};
            }
        },
        _stop => sub {
            pass "_stop";
        },
    },
);

$poe_kernel->run();

pass "Stopped";
