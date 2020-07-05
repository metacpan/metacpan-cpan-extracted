use strict;
use warnings;
use Test::Most;

use constant TYPE_CONSTRAINT_FAILED => qr/did not pass type constraint/;

package Some::Interface {
    use Role::Declare;
    use Types::Standard qw[ Str Int ];

    class_method foo (Str $s, Int $i, Int $j) :Return(Str) {
        die "$j is greater than $i" if $i <= $j;
    }

    class_method bar (Int $i) :ReturnList(Str) {}

    class_method multi () :Return(Str) :ReturnList(Int, 2, 4) { }

    class_method list_maybe() :ReturnMaybeList(Int, 2, 4) {}

    class_method hash($case = undef) :ReturnHash(Int) {}

    class_method tuple() :ReturnTuple(Int, Str, Int) {}
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

    sub hash {
        return (a => 1, b => 2);
    }

    sub tuple {
        return (1, 'x', 2);
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

    sub hash {
        my ($class, $case) = @_;
        return ( 'a', 'b', 'c' )      if $case == 1;
        return { a => 1, b => 2 }     if $case == 2;
        return ( a => 1, b => 'xxx' ) if $case == 3;
        die;
    }

    sub tuple {
        return (1, 'x');
    }
}


is(scalar Good->foo('Diff', 5, 2), 'Diff: 3', 'scalar return');
is_deeply [ Good->bar(1) ], [ 'X:1', 'Y:1' ], 'list return';

is scalar Good->multi(), 'X', 'scalar return from context aware method';
is_deeply [ Good->multi() ], [ 1, 2, 3 ], 'list return from context aware method';

is_deeply [ Good->list_maybe() ], [], 'empty list return with ReturnListMaybe';

my %hash = Good->hash();
is_deeply \%hash, { a => 1, b => 2 }, 'hash kv pairs returned';

is_deeply [ Good->tuple ], [ 1, 'x', 2 ], 'tuple returned';

throws_ok {
    Good->foo('Diff', 2, 5)
} qr/5 is greater than 2/, 'assertion failed';

throws_ok {
    Good->foo('Diff', 2, 5, 'NOT NEEDED')
} qr/Too many arguments/, 'extra arguments';

throws_ok {
    Good->foo('Diff', 'Two', 'Five')
} TYPE_CONSTRAINT_FAILED, 'wrong argument type';

throws_ok {
    my $result = Bad->foo('Diff', 5, 2)
} TYPE_CONSTRAINT_FAILED, 'wrong scalar return type';

throws_ok { my @result = Bad->multi() } TYPE_CONSTRAINT_FAILED,
  'wrong number of elements in list context';

throws_ok { my @result = Bad->list_maybe() } TYPE_CONSTRAINT_FAILED,
  'invalid non-empty list returned under ReturnListMaybe';

foreach my $case ( 1 .. 3 ) {
    throws_ok { my %result = Bad->hash($case) }
      TYPE_CONSTRAINT_FAILED, "invalid hash return $case";
}

throws_ok { my @tuple = Bad->tuple() } TYPE_CONSTRAINT_FAILED, 'invalid tuple returned';

done_testing();
