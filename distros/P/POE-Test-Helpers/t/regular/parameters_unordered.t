#!perl

# testing event parameters
# this allows to set each event with sets of parameters
# these are the parameters that it MUST have
# and they are in the order in which it's required
package Session;

use Test::More tests => 4;
use POE::Test::Helpers;

use POE;

my $flag = 0;
POE::Test::Helpers->spawn(
    run => sub {
        POE::Session->create(
            inline_states => {
                _start => sub { $_[KERNEL]->yield( 'next', 'goodbye' ) },
                next   => sub { $_[KERNEL]->yield('more') },
                more   => sub {
                    $flag++ || $_[KERNEL]->yield( 'next', 'hello', 'world' );
                },
            },
        );
    },

    params_type => 'unordered',
    tests => {
        'next' => { params => [ [ 'hello', 'world' ], ['goodbye'] ] },
        'more' => { params => [ [] ] },
    },
);

POE::Kernel->run();

