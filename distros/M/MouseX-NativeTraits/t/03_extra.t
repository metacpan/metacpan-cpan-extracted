#!perl -w
# Mouse specific features
use strict;
use Test::More;

{
    package MyClass;
    use Mouse;

    has list => (
        is  => 'rw',
        isa => 'ArrayRef',

        traits => ['Array'],

        handles => {
            any              => 'any',
            sort_by          => 'sort_by',
            sort_in_place_by => 'sort_in_place_by',
            apply            => 'apply',
            map              => 'map',
        },
        default => sub{ [] },
    );

    has hash => (
        is  => 'rw',
        isa => 'HashRef',

        traits => ['Hash'],

        handles => {
           sorted_keys => 'sorted_keys', 
        },
        default => sub{ {} },
    );
}

my $o = MyClass->new(list => [ {value => 3}, {value => 10}, { value => 0 } ]);

note 'Array';

ok $o->any(sub{ $_->{value} == 0 }), 'any';

is join(' ', map{ $_->{value} } $o->sort_by(sub{ $_->{value} }, sub{ $_[0] <=> $_[1] })),
    '0 3 10', 'sort_by';

$o->sort_in_place_by(sub{ $_->{value} }, sub{ $_[0] <=> $_[1] });

is join(' ', $o->map(sub{ $_->{value} })),
    '0 3 10', 'sort_in_place_by';
is join(' ', $o->apply(sub{ $_ = $_->{value} })),
    '0 3 10', 'apply';

is join(' ', $o->map(sub{ $_->{value} })),
    '0 3 10', 'apply does not affect the original value';

note 'Hash';

$o->hash({ 'a' => 10, 'b' => 20, 'c' => 30 });
is join(' ', $o->sorted_keys), 'a b c', 'sorted_keys';

done_testing;
