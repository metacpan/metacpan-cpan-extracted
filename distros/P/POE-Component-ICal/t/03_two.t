use strict;
use warnings;

use Test::More;
use POE;
use POE::Component::ICal;

my $tick_count = 5;
my $tock_count = 2;
plan(tests => ($tick_count * 4) + 2 + ($tock_count * 4) + 2 + 1);

POE::Session->create
(
    inline_states =>
    {
        _start => sub
        {
            pass('_start');
            POE::Component::ICal->add_schedule
            (
                  'tick'                                         # schedule
                , clock => { freq => 'secondly', interval => 1 } # event => ical
                , 'tick'                                         # ARG0
                , \$tick_count                                   # ARG1
            );
            POE::Component::ICal->add_schedule
            (
                  'tock'                                         # schedule
                , clock => { freq => 'secondly', interval => 2 } # event => ical
                , 'tock'                                         # ARG0
                , \$tock_count                                   # ARG1
            );
        },
        clock => sub
        {
            is($#_ - ARG0, 1, 'Number of arguments');
            my ($schedule, $ref_count) = @_[ARG0, ARG1];
            like($schedule, qr/^(tick|tock)$/, 'ARG0 name');
            is(ref $ref_count, 'SCALAR', 'ARG1 type');
            ok($$ref_count > 0, 'ARG1 > 0');
            if (--$$ref_count == 0)
            {
                pass("remove $schedule");
                POE::Component::ICal->remove($schedule);
            }
        },
        _stop => sub
        {
            pass('_stop');
        }
    }
);

POE::Kernel->run;

ok(1);
