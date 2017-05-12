
=for Explanation:
     Check the object oriented interface of the OOB module

=cut

BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

# be as strict and verbose
use strict;
use warnings;

use Test::More tests => 2 * 8 * 7;

use OOB qw( CompileTime );

# test unblessed and blessed
OOB->Attribute;
foreach my $class ( '', 'Foo' ) {
    my $scalar = ''; # prevent undefined warnings
    my @array;
    my %hash;

    # given types
    no warnings 'once';
    foreach my $ref (
      $scalar,
      \$scalar,
      \@array,
      \%hash,
      [],
      {},
      eval "sub { 1 }",
      \*FILE,
      ) {
      SKIP: { skip "Can only bless references", 7
          if $class and !ref $ref;
        $ref = bless $ref, $class if $class;

        my $value = int rand 1000;
        OOB->Attribute( $ref, $value );
        is( OOB->Attribute($ref), $value,
          "Check value Attribute: $ref" );

        OOB->CompileTime( $ref, $value );
        is( OOB->CompileTime($ref), $value,
          "Check value CompileTime: $ref" );

        my $value2 = int rand 1000;
        is( OOB->Attribute( $ref, $value2 ), $value,
          "Check return of first value: $ref" );

        is( OOB->Attribute($ref), $value2,
          "Check second value: $ref" );

        my $result = eval { OOB->Huh($ref); 1; };
        ok( $result, "Accept non existing attribute accessor: $ref $@" );

        $result = eval { OOB->Huh( $ref, 1 ); 1; };
        ok( !$result, "Fail non existing attribute mutator: $ref $@" );

        is( OOB->CompileTime($ref), $value,
          "Check value CompileTime 2nd time: $ref" );
        };
    }
}
