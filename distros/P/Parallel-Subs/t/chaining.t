use strict;
use warnings;

use Test::More;

use_ok 'Parallel::Subs';

use Parallel::Subs;

my $p = Parallel::Subs->new()
    ->add( sub { print "Hello from kid $$\n"; } ) #
    ->add( sub { print "Hello from kid $$\n"; } ) #
    ->add( sub { print "Hello from kid $$\n"; } ) #
    ->add( sub { print "Hello from kid $$\n"; } ) #
    ->add( sub { print "Hello from kid $$\n"; } ) #
    ->add( sub { print "Hello from kid $$\n" } )  #
    ->wait_for_all();

isa_ok $p, 'Parallel::Subs';
ok 1, q[This is done.];

done_testing;
