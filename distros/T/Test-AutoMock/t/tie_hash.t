use strict;
use warnings;
use Test::More import => [qw(ok eq_set is is_deeply done_testing)];
use Test::AutoMock qw(mock_overloaded manager);

{
    my $mock = mock_overloaded;
    my $hash = $mock->ref_hash;

    # FETCh
    my $abc = $hash->{abc};
    $abc->some_other_method;

    # STORE
    $hash->{def} = 'XYZ';
    is "$hash->{def}", 'XYZ';

    # DELETE
    delete $hash->{def};
    ok $hash->{def} ? 1 : 0;

    # CLEAR
    %$hash = ();

    # EXISTS
    ok ! exists $hash->{ghi};

    # FIRSTKEY, NEXTKEY
    $hash->{jkl} = 1;
    $hash->{mno} = 2;
    ok eq_set [keys %$hash], [qw(jkl mno)];

    is scalar %$hash, 2;

    my @calls = manager($mock)->calls;
    is @calls, 16;
    is_deeply $calls[0], ['ref_hash', []];
    is_deeply $calls[1], ['ref_hash->{abc}', []];
    is_deeply $calls[2], ['ref_hash->{abc}->some_other_method', []];
    is_deeply $calls[3], ['ref_hash->{def}', ['XYZ']];
    is_deeply $calls[4], ['ref_hash->{def}', []];
    is_deeply $calls[5], ['ref_hash->DELETE', ['def']];
    is_deeply $calls[6], ['ref_hash->{def}', []];
    is_deeply $calls[7], ['ref_hash->{def}->`bool`', [undef, '']];
    is_deeply $calls[8], ['ref_hash->CLEAR', []];
    is_deeply $calls[9], ['ref_hash->EXISTS', ['ghi']];
    is_deeply $calls[10], ['ref_hash->{jkl}', [1]];
    is_deeply $calls[11], ['ref_hash->{mno}', [2]];
    is_deeply $calls[12], ['ref_hash->FIRSTKEY', []];
    is $calls[13]->[0], 'ref_hash->NEXTKEY';
    is $calls[14]->[0], 'ref_hash->NEXTKEY';
    is_deeply $calls[15], ['ref_hash->SCALAR', []];
}

done_testing;
