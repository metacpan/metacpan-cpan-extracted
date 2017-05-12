#!perl
use strict;
use warnings;
use Test::More tests => 13;
use Operator::Util qw( cross crosswith );

{
    my @result = cross ['a','b'], [1,2];
    is_deeply \@result, [qw< a 1 a 2 b 1 b 2 >],
    'cross() produces expected result';

}

is_deeply [crosswith '**', [1,2,3], [2,4]], [1,1,4,16,9,81], 'crosswith(**) works';

# This becomes a flat list in
{
    my @result = cross [1,2,3], ['a','b'];
    is_deeply \@result, [qw< 1 a 1 b 2 a 2 b 3 a 3 b >], 'flat cross() works';
}

# and a list of arrays in
SKIP: {
    skip 'flat=>0 NYI', 1;
    my @result = map { join ':', @$_ } cross([1,2,3], ['A','B'], flat => 0);
    is \@result, [qw< 1:A 1:B 2:A 2:B 3:A 3:B >], 'non-flat cross() works';
}

# string concatenating form is
{
    my @result = crosswith '.', ['a','b'], [1,2];
    is_deeply \@result, [qw< a1 a2 b1 b2 >],
        'crosswith(.) produces expected result';
}

# list concatenating form when used like this
TODO: {
    local $TODO = '3+ list crosswith NYI';
    my @result = crosswith ',', ['a','b'], [1,2], ['x','y'];
    is scalar @result, 24, '3-list crosswith(,) produces correct number of elements';

    my @expected = (
        ['a', 1, 'x'],
        ['a', 1, 'y'],
        ['a', 2, 'x'],
        ['a', 2, 'y'],
        ['b', 1, 'x'],
        ['b', 1, 'y'],
        ['b', 2, 'x'],
        ['b', 2, 'y'],
    );
    is_deeply \@result, \@expected, '3-list crosswith(,) produces correct results';
}

# any existing non-mutating infix operator
is_deeply [crosswith '*', [1,2], [3,4]], [3,4,6,8], 'crosswith(*) works';

is_deeply [crosswith '<=>', [1,2], [3,2,0]], [-1,-1,1,-1,0,1], 'crosswith(<=>) works';

# underlying operator non-associating
TODO: {
    local $TODO = 'non-associating op error NYI';
    ok !crosswith('cmp', ['a','b'], [1,2], ['x','y']),
        'non-associating ops cannot have 3+ lists';
}

# tests for non-list arguments
is_deeply [crosswith '*', 1, [3,4]], [3,4], 'crosswith(*) works with scalar left side';
is_deeply [crosswith '*', [1,2], 3], [3,6], 'crosswith(*) works with scalar right side';
is_deeply [crosswith '*', 1, 3], [3], 'crosswith(*) works with scalar both sides';
