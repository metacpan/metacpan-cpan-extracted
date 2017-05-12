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
        <STR>      { return 'STR'     }
        <BOOL>     { return 0         }
        <INT>      { return 42        }
        <NUM>      { return 12.34     }
        <REGEXP>   { return qr{food?} }
        <SCALAR>   { return \$scalar  }
        <ARRAY>    { return \@array   }
        <HASH>     { return \%hash    }
        <CODE>     { return \&code    }
        <GLOB>     { return $glob_ref }
    };
}

my $result = get_result();

is $result, 'STR'             => 'String coercion';
ok !$result                   => 'Boolean coercion';
cmp_ok $result+0, '==', 12.34 => 'Number coercion';
is int($result), 42           => 'Explicit integer coercion';
is $array[$result], 'twelve'  => 'Implicit numeric coercion';

is $$result, $scalar            => 'Scalar deref';
cmp_ok \@$result, '==', \@array => 'Array deref';
cmp_ok \%$result, '==', \%hash  => 'Hash deref';
is $result->(), code(),         => 'Code deref';
is readline($result), $scalar   => 'Glob_deref';

done_testing();


