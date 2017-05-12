#!perl -w

use strict;
use Test::More;

{
    package MyClass;
    use Any::Moose;

    has stack => (
        is  => 'rw',
        isa => 'ArrayRef',

        traits => ['Array'],

        handles => {
            pop            => 'pop',
            push           => 'push',
            top            => [ get => -1 ],
            stack_is_empty => 'is_empty',
        },
        default => sub{ [] },
    );

    has mapping => (
        is  => 'rw',
        isa => 'HashRef',

        traits => ['Hash'],

        handles => {
            keys    => 'keys',
            values  => 'values',
            store_to_map => 'set',
            map_count    => 'count',
        },
        default => sub{ +{} },
    );
}

my $o = MyClass->new();

note 'Array';
$o->push(10);
is $o->top, 10;

$o->push(20);
is $o->top, 20;

ok !$o->stack_is_empty;

is $o->pop, 20;
is $o->top, 10;
is $o->pop, 10;
is $o->pop, undef;

ok $o->stack_is_empty;

note 'Hash';

$o->store_to_map(aaa => 42, bbb => 10);
is join(' ', sort $o->keys),   'aaa bbb';
is join(' ', sort $o->values), '10 42';
is $o->map_count, 2;

$o->store_to_map(ccc => 99);
is join(' ', sort $o->keys),   'aaa bbb ccc';
is join(' ', sort $o->values), '10 42 99';
is $o->map_count, 3;

done_testing;
