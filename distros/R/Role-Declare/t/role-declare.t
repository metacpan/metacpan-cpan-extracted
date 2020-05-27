use strict;
use warnings;
use Test::Most;

package Some::Interface {
    use Role::Declare;
    use Types::Standard qw[ Str Int ];

    class_method foo (Str $s, Int $i, Int $j) :Return(Str) {
        die "$j is greater than $i" if $i <= $j;
    }

    class_method bar (Int $i) :ReturnList(Str) {}

    class_method multi () :Return(Str) :ReturnList(Int, 2, 4) { }

    class_method list_maybe() :ReturnMaybeList(Int, 2, 4) {}
}

package Good {
    use Role::Tiny::With;
    with 'Some::Interface';

    sub foo {
        my ( $self, $s, $i, $j ) = @_;
        return "$s: " . ($i - $j);
    }

    sub bar {
        my ($self, $i) = @_;
        return ("X:$i", "Y:$i");
    }

    sub multi {
        return (1, 2, 3) if wantarray;
        return 'X';
    }

    sub list_maybe {
        return;
    }
}


package Bad {
    use Role::Tiny::With;
    with 'Some::Interface';

    sub foo {
        my ( $self, $s, $i, $j ) = @_;
        return bless {};
    }

    sub bar {} 

    sub multi {
        return ( 1, 2, 3, 4, 5 );
    }

    sub list_maybe {
        return (1);
    }
}


is(scalar Good->foo('Diff', 5, 2), 'Diff: 3', 'scalar return');
is_deeply [ Good->bar(1) ], [ 'X:1', 'Y:1' ], 'list return';

is scalar Good->multi(), 'X', 'scalar return from context aware method';
is_deeply [ Good->multi() ], [ 1, 2, 3 ], 'list return from context aware method';

is_deeply [ Good->list_maybe() ], [], 'empty list return with ReturnListMaybe';

throws_ok {
    Good->foo('Diff', 2, 5)
} qr/5 is greater than 2/, 'assertion failed';

throws_ok {
    Good->foo('Diff', 2, 5, 'NOT NEEDED')
} qr/Too many arguments/, 'extra arguments';

throws_ok {
    Good->foo('Diff', 'Two', 'Five')
} qr/did not pass type constraint/, 'wrong argument type';

throws_ok {
    my $result = Bad->foo('Diff', 5, 2)
} qr/did not pass type constraint/, 'wrong scalar return type';

throws_ok { my @result = Bad->multi() } qr/did not pass type constraint/,
  'wrong number of elements in list context';

throws_ok { my @result = Bad->list_maybe() } qr/did not pass type constraint/,
  'invalid non-empty list returned under ReturnListMaybe';

done_testing();
