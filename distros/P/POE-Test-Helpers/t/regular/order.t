#!perl

# testing ordered events
# this method was first written by ADAMK
# and can be found in POE::Declare t/04-stop.t
package Session;

use Test::More tests => 4;
use POE::Test::Helpers;

use POE;

POE::Test::Helpers->spawn(
    run => sub {
        POE::Session->create(
            inline_states => {
                _start => sub { $_[KERNEL]->yield('next') },
                next   => sub { $_[KERNEL]->yield('last') },
                last   => sub {1},
                _stop  => sub {1},
            },
        );
    },

    tests => {
        '_start' => { order => 0 },
        'next'   => { order => 1 },
        'last'   => { order => 2 },
        '_stop'  => { order => 3 },
    },
);

POE::Kernel->run();

