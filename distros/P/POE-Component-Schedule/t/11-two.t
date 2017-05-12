use Test::More tests => 21;

use POE;
use POE::Component::Schedule;
use DateTime;
use DateTime::Set;


my $max = 2;

POE::Session->create(
    inline_states => {
        _start => sub {
            pass "_start";
            my $tick_count = 3;
            my $tock_count = 1;
            POE::Component::Schedule->spawn(Alias => 'TickTock');
            POE::Component::Schedule->spawn(); # Second call to reach 100% test coverage
            $_[HEAP]{Tick} = POE::Component::Schedule->add(
                $_[SESSION], Clock => DateTime::Set->from_recurrence(
                        after      => DateTime->now->add( seconds => 1),
                        recurrence => sub {
                            return $_[0]->truncate( to => 'second' )->add( seconds => 1 )
                        },
                    ),
                'Tick', \$tick_count
            );
            $_[HEAP]{Tock} = POE::Component::Schedule->add(
                $_[SESSION] => Clock => DateTime::Set->from_recurrence(
                        after      => DateTime->now->add( seconds => 1),
                        recurrence => sub {
                            return $_[0]->truncate( to => 'second' )->add( seconds => 2 )
                        },
                    ),
                'Tock', \$tock_count
            );
        },
        Clock => sub {
            # ARG0 : schedule name
            # ARG1 : schedule counter reference
            is($#_ - ARG0, 1, $_[STATE].' arg count');
            my ($s, $rc) = @_[ARG0, ARG1];
            like($s, qr/^(?:Tick|Tock)$/, "ARG0");
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
        _stop => sub {
            pass "_stop";
        },
    },
);

$poe_kernel->run();

pass "Stopped";