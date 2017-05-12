#!perl

# testing sequenced ordered events
# this is a more relaxed and flexible implementation of ADAMK's version
# it allows to define order by previous occured events
# instead of number of specific occurrence.
# that way, you can define which events should have preceded
# instead of what exact global order it had

package Session;
use Test::More tests => 3;
use MooseX::POE;
with 'POE::Test::Helpers::MooseRole';
has '+tests' => ( default => sub { {
    'next'   => { deps => [ '_start'                 ] },
    'last'   => { deps => [ '_start', 'next'         ] },
    '_stop'  => { deps => [ '_start', 'next', 'last' ] },
} } );

sub START           { $_[KERNEL]->yield('next') }
event 'next' => sub { $_[KERNEL]->yield('last') };
event 'last' => sub { 1 };

package main;
use POE::Kernel;
Session->new();
POE::Kernel->run();

