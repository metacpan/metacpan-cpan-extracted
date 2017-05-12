#!perl

# testing ordered events
# this method was first written by ADAMK
# and can be found in POE::Declare t/04-stop.t

# the Role provided simply runs the tests for the session
package Session;
use Test::More tests => 4;
use MooseX::POE;
with 'POE::Test::Helpers::MooseRole';
has '+tests' => ( default => sub { {
    '_start' => { order => 0 },
    'next'   => { order => 1 },
    'last'   => { order => 2 },
    '_stop'  => { order => 3 },
} } );
sub START { $_[KERNEL]->yield('next') }
event 'next' => sub { $_[KERNEL]->yield('last') };
event 'last' => sub {};
sub STOP {}

package main;
use POE::Kernel;
Session->new();
POE::Kernel->run();

