#!perl

# testing event parameters
# this allows to set each event with sets of parameters
# these are the parameters that it MUST have
# and they are in the order in which it's required

package Session;
use Test::More tests => 4;
use MooseX::POE;
with 'POE::Test::Helpers::MooseRole';
has '+tests' => ( default => sub { {
    'next' => { params => [ [ 'hello', 'world' ], [ 'goodbye' ] ] },
    'more' => { params => [ [] ] },
} } );
has '+params_type' => ( default => 'unordered' );

my $flag = 0;
sub START           { $_[KERNEL]->yield( 'next', 'goodbye' ) }
event 'next' => sub { $_[KERNEL]->yield( 'more'            ) };
event 'more' => sub {
    $flag++ || $_[KERNEL]->yield( 'next', 'hello', 'world' );
};

package main;
use POE::Kernel;
Session->new();
POE::Kernel->run();

