
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

use Test::More tests => 2 * 8 * 5;

use OOB qw( OOB_get OOB_set );

# test unblessed and blessed
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
      SKIP: { skip "Can only bless references", 5
          if $class and !ref $ref;
        $ref = bless $ref, $class if $class;

        my $value = int rand 1000;
        OOB_set( $ref, Attribute => $value );
        is( OOB_get( $ref => 'Attribute' ), $value,
          "Check value Attribute: $ref" );

        OOB_set( $ref, CompileTime => $value );
        is( OOB_get( $ref => 'CompileTime' ), $value,
          "Check value CompileTime: $ref" );

        my $value2 = int rand 1000;
        is( OOB_set( $ref, Attribute => $value2 ), $value,
          "Check return of first value: $ref" );

        is( OOB_get( $ref => 'Attribute' ), $value2,
          "Check second value: $ref" );

        is( OOB_get( $ref => 'CompileTime' ), $value,
          "Check value CompileTime 2nd time: $ref" );
        };
    }
}
