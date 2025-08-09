#!perl

use Test::Most;

use lib 't/lib';
use MooTest;

ok my $o = MooTest->new( cr => 4 ), "new test object";

lives_ok {
    ++$o->foo->[0];
} 'allowed change of array element';

is $o->foo->[0] => 2, 'element was changed';

dies_ok {
    ++$o->bar->[0];
} 'disallowed change of array element';

is $o->bar->[0] => 1, 'element was not changed';

dies_ok {

    $o->bop->{y};

} 'cannot access a non-existent key attribute (read-only)';

lives_ok {

    $o->bo( { a => 1, b => 2 } );

} 'set a write-once attribute';

dies_ok {

    ++$o->bo->{a};

} 'cannot write again to a write-once attribute';

dies_ok {

    $o->bo->{c};

} 'cannot access a non-existent key attribute (write once)';


ok $o->cr, "can access sub isa attribute";

dies_ok {

    $o->cr(10);

} 'cannot change sub isa attribute';

done_testing;
