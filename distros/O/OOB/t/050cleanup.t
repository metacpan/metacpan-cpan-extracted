
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

my @warnings;
BEGIN {
    $ENV{OOB_DEBUG} = 1;
    $SIG{__WARN__}  = sub { push @warnings, $_[0] };
}    #BEGIN

use Test::More tests => 7 * 2;

use OOB qw( Attribute );

use Scalar::Util qw( blessed );

foreach my $sub (
    sub {
        my $scalar = '';
        OOB->Attribute( $scalar, 'foo' );
    },
    sub {
        my $other;
        OOB->Attribute( \$other, 'foo' );
    },
    sub {
        my @array;
        OOB->Attribute( \@array, 'foo' );
    },
    sub {
        my %hash;
        OOB->Attribute( \%hash, 'foo' );
    },
    sub {
        OOB->Attribute( [], 'foo' );
    },
    sub {
        OOB->Attribute( {}, 'foo' );
    },
    sub {
        OOB->Attribute( eval "sub { 1 }", 'foo' );
    },
    ) {

    @warnings = ();
    &$sub;

    is( scalar @warnings, 1, "should only have one warning" );
    ok( $warnings[0] =~ m#^OOB::DESTROY with OOB=#, 'destruction ok' );
}
