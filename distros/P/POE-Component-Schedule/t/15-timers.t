use Test::More tests => 12;

# This test check that standard timers can be used aside P::C::S events

sub POE::Component::Schedule::DEBUG() { 1 }

use POE qw(Component::Schedule);
use DateTime;
use DateTime::Set;


my $end_timer_fired = 0;

POE::Session->create(
    inline_states => {
        _start => sub {
            pass "_start";
            $poe_kernel->delay(EndTimer => 4);
            my $tick_count = 2;
            $_[HEAP]{Tick} = POE::Component::Schedule->add(
                $_[SESSION], Clock => DateTime::Set->from_recurrence(
                        after      => DateTime->now->add( seconds => 1),
                        recurrence => sub {
                            return $_[0]->truncate( to => 'second' )->add( seconds => 1 )
                        },
                    ),
                'Tick', \$tick_count
            );
        },
        Clock => sub {
            # ARG0 : schedule name
            # ARG1 : schedule counter reference
            is($#_ - ARG0, 1, $_[STATE].' arg count');
            my ($s, $rc) = @_[ARG0, ARG1];
            is(ref $rc, 'SCALAR', "ARG1 type");
            diag "$s ".$$rc;
            ok($$rc > 0, "ARG1 > 0");
            diag scalar localtime;
            if (--$$rc == 0) {
                pass "delete $s";
                $_[HEAP]{$s}->delete;
                delete $_[HEAP]{$s};
            }
        },
        EndTimer => sub {
            $end_timer_fired++;
            pass "EndTimer";
            diag scalar localtime;
        },
        _stop => sub {
            pass "_stop";
        },
    },
);

$poe_kernel->run();

pass "Stopped";

ok($end_timer_fired, "EndTimer fired");
