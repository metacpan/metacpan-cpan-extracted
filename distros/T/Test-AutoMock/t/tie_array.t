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

    my @expected = (
        ['ref_array', []],
        ['ref_array->[0]', []],
        ['ref_array->[0]->some_other_method', []],
        ['ref_array->[1]', [10]],
        ($] < 5.020 ? (['ref_array->FETCHSIZE', []]) : ()),
        ['ref_array->[1]', []],
        ['ref_array->FETCHSIZE', []],
        ['ref_array->STORESIZE', [3]],
        ['ref_array->FETCHSIZE', []],
        ['ref_array->CLEAR', []],
        ($] < 5.024 ? (['ref_array->EXTEND', [0]]) : ()),
        ['ref_array->PUSH', [0, 10, 20]],
        ($] < 5.012 ? (['ref_array->FETCHSIZE', []]) : ()),
        ['ref_array->POP', []],
        ['ref_array->SHIFT', []],
        ['ref_array->UNSHIFT', [30, 40, 50]],
        ($] < 5.012 ? (['ref_array->FETCHSIZE', []]) : ()),
        ['ref_array->SPLICE', [1, 2]],
        ['ref_array->DELETE', [0]],
        ['ref_array->EXISTS', [1]],
        ['ref_array->FETCHSIZE', []],
    );

    my @calls = manager($mock)->calls;
    is_deeply \@calls, \@expected;
}

done_testing;
