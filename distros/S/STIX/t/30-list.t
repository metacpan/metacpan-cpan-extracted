#!perl

use strict;
use warnings;

use Test::More;
use STIX::Common::List;

my $collection = STIX::Common::List->new(1, 2, 3);

subtest 'size' => sub {

    is($collection->size, 3, 'Test size #1');
    $collection->push(4);

    is($collection->size, 4, 'Size #2');

};

is($collection->pop,   4, 'Test pop');
is($collection->first, 1, 'Test first #1');
is($collection->last,  3, 'Test last');

$collection->unshift(0);

is($collection->first, 0, 'Test first #2');

is($collection->get(0), 0, 'Test get #0');
is($collection->get(1), 1, 'Test get #1');
is($collection->get(2), 2, 'Test get #2');
is($collection->get(3), 3, 'Test get #3');

isnt($collection->get(4), 4, 'Test get undef');

subtest 'join' => sub {
    is($collection->join,      '0123',    'Test join #1');
    is($collection->join(','), '0,1,2,3', 'Test join #2');
};

subtest 'to_array' => sub {
    isa_ok($collection->to_array, 'ARRAY', 'Test to_array #1');
    isa_ok(\@{$collection},       'ARRAY', 'Test to_array #2');
};

subtest 'each' => sub {

    is_deeply [$collection->each], [0, 1, 2, 3], 'Test each #1';

    my @test = ();
    $collection->each(sub { push @test, $_[0] });

    is_deeply \@test, [0, 1, 2, 3], 'Test each #2';

};

$collection->clear;
is($collection->size, 0, 'Clear');

$collection->set(0, 'test');
is($collection->first, 'test', 'Test set');

is($collection->pop, 'test', 'Test pop');

done_testing();
