use 5.014;
use Test::More;
use Object::Result;

my $scalar = 'scalar variable';
my @array  = qw< array variable >; $array[12] = 'twelve';
my %hash   = qw< hash  variable >;
sub code { return 'subroutine' }
open my $glob_ref, '<', \$scalar;

sub get_result {
    result {
        <REGEXREF>  { return qr{food?} }
        <SCALARREF> { return \$scalar  }
        <ARRAYREF>  { return \@array   }
        <HASHREF>   { return \%hash    }
        <SUBREF>    { return \&code    }
        <GLOBREF>   { return $glob_ref }
    };
}

my $result = get_result();

is $$result, $scalar            => 'Scalar deref';
cmp_ok \@$result, '==', \@array => 'Array deref';
cmp_ok \%$result, '==', \%hash  => 'Hash deref';
is $result->(), code(),         => 'Code deref';
is readline($result), $scalar   => 'Glob_deref';

done_testing();



