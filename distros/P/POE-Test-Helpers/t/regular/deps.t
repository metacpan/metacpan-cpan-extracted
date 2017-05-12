#!perl

# testing sequenced ordered events
# this is a more relaxed and flexible implementation of ADAMK's version
# it allows to define order by previous occured events
# instead of number of specific occurrence.
# that way, you can define which events should have preceded
# instead of what exact global order it had

package Session;

use Test::More tests => 3;
use POE::Test::Helpers;

use POE;

POE::Test::Helpers->spawn(
    run => sub {
        POE::Session->create(
            inline_states => {
                _start => sub { $_[KERNEL]->yield('next') },
                next   => sub { $_[KERNEL]->yield('last') },
                last   => sub {1},
            },
        );
    },

    tests => {
        'next'  => { deps => [ '_start'                 ] },
        'last'  => { deps => [ '_start', 'next'         ] },
        '_stop' => { deps => [ '_start', 'next', 'last' ] },
    },
);

POE::Kernel->run();

