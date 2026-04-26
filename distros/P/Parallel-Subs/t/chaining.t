use strict;
use warnings;

use Test2::V0;

use Parallel::Subs;

subtest 'chained add + wait_for_all' => sub {
    my $p = Parallel::Subs->new()
        ->add( sub { 1 } )
        ->add( sub { 2 } )
        ->add( sub { 3 } )
        ->add( sub { 4 } )
        ->add( sub { 5 } )
        ->add( sub { 6 } )
        ->wait_for_all();

    isa_ok $p, 'Parallel::Subs';
    is $p->results(), [ 1 .. 6 ], "chained jobs return correct results";
};

subtest 'chained add returns self' => sub {
    my $p = Parallel::Subs->new();
    my $ret = $p->add( sub { 42 } );
    ref_is $ret, $p, "add() returns the object for chaining";
};

done_testing;
