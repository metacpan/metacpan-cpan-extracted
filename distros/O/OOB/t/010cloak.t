
=for Explanation:
     Check the cloaking of BOO blessed objects from the ref() and
     Scalar::Util::blessed() functions.

=cut

BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

# be as strict and verbose as possible
use strict;
use warnings;

use Test::More tests => 2 * 8 * 4;

use OOB qw( Attribute );

use Scalar::Util qw( blessed );

# test unblessed and blessed
foreach my $class ( '', 'Foo' ) {
    my $scalar = ''; # prevent undefined warnings
    my $other;
    my @array;
    my %hash;

    # given types
    no warnings 'once';
    foreach my $ref (
      $scalar,
      \$other,
      \@array,
      \%hash,
      [],
      {},
      eval "sub { 1 }",
      \*FILE,
      ) {

      SKIP: { skip "Can only bless references", 4
          if $class and !CORE::ref $ref;
        $ref = bless $ref, $class if $class;

        my $real_ref     = ref $ref;
        my $real_blessed = blessed $ref;

        is( $real_ref, CORE::ref( $ref ),
          'Same as CORE ref' );
        is( $real_blessed, OOB::function::blessed( $ref ),
          'Same as CORE blessed' );

        OOB->Attribute( $ref, 'Foo' );
        is( ref( $ref ), $real_ref,
          'Still same as CORE ref' );
        is( blessed( $ref ), $real_blessed,
          'Still same as CORE blessed' );
        };
    }
}
