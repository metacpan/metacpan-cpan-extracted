use strict;
use warnings;
use Test::More import => [qw(ok is is_deeply done_testing)];
use Test::AutoMock qw(mock_overloaded manager);

{
    my $mock = mock_overloaded;
    my $array = $mock->ref_array;

    # FETCH
    my $abc = $array->[0];
    $abc->some_other_method;

    # STORE
    $array->[1] = 10;
    is $array->[1], 10;

    # FETCHSIZE
    is scalar @$array, 2;

    # STORESIZE
    $#$array = 2;
    is scalar @$array, 3;

    # CLEAR
    @$array = ();

    # PUSH
    push @$array, 0, 10, 20;

    # POP
    is pop @$array, 20;

    # SHIFT
    is shift @$array, 0;

    # UNSHIFT
    unshift @$array, 30, 40, 50;

    # SPLICE
    splice @$array, 1, 2, ();

    # DELETE
    delete $array->[0];

    # EXISTS
    ok exists $array->[1];

    # assert size of array
    is scalar @$array, 2;

    my @calls = manager($mock)->calls;
    is @calls, 17;
    is_deeply $calls[0], ['ref_array', []];
    is_deeply $calls[1], ['ref_array->[0]', []];
    is_deeply $calls[2], ['ref_array->[0]->some_other_method', []];
    is_deeply $calls[3], ['ref_array->[1]', [10]];
    is_deeply $calls[4], ['ref_array->[1]', []];
    is_deeply $calls[5], ['ref_array->FETCHSIZE', []];
    is_deeply $calls[6], ['ref_array->STORESIZE', [3]];
    is_deeply $calls[7], ['ref_array->FETCHSIZE', []];
    is_deeply $calls[8], ['ref_array->CLEAR', []];
    is_deeply $calls[9], ['ref_array->PUSH', [0, 10, 20]];
    is_deeply $calls[10], ['ref_array->POP', []];
    is_deeply $calls[11], ['ref_array->SHIFT', []];
    is_deeply $calls[12], ['ref_array->UNSHIFT', [30, 40, 50]];
    is_deeply $calls[13], ['ref_array->SPLICE', [1, 2]];
    is_deeply $calls[14], ['ref_array->DELETE', [0]];
    is_deeply $calls[15], ['ref_array->EXISTS', [1]];
    is_deeply $calls[16], ['ref_array->FETCHSIZE', []];
}

done_testing;
