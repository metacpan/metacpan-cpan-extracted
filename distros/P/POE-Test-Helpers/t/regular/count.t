#!perl

# testing sequenced ordered events
# this is a more relaxed and flexible implementation of ADAMK's version
# it allows to define order by previous occured events
# instead of number of specific occurrence.
# that way, you can define which events should have preceded
# instead of what exact global order it had

package Session;

use Test::More tests => 5;
use POE::Test::Helpers;

use POE;

my $count = 0;
POE::Test::Helpers->spawn(
    run => sub {
        POE::Session->create(
            inline_states => {
                _start => sub { $_[KERNEL]->yield('next') },
                next   => sub { $_[KERNEL]->yield('more') },
                more   => sub {
                    $count++ < 3 ? $_[KERNEL]->yield('next') :
                                   $_[KERNEL]->yield('last');
                },
                last   => sub {1},
            },
        );
    },

    tests => {
        '_start' => { count => 1 },
        'next'   => { count => 4 },
        'more'   => { count => 4 },
        'last'   => { count => 1 },
        '_stop'  => { count => 1 },
    },
);

POE::Kernel->run();

