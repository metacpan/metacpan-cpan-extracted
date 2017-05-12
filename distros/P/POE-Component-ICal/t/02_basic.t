use strict;
use warnings;

use Test::More;
use POE;
use POE::Component::ICal;

my $count = 5;
plan(tests => $count + 2 + 1);

POE::Session->create
(
    inline_states =>
    {
        _start => sub
        {
            pass('_start');
            $_[HEAP]{count} = $count;
            POE::Component::ICal->add(tick => { freq => 'secondly', interval => 1 });
        },
        tick => sub
        {
            pass('tick ' . --$_[HEAP]{count});
            POE::Component::ICal->remove_all if $_[HEAP]{count} == 0;
        },
        _stop => sub
        {
            pass('_stop');
        }
    }
);

POE::Kernel->run;

ok(1);
