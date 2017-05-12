use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

BEGIN {
    package TypeLib;
    use MooseX::Types -declare => [qw/
    MyChar MyDigit ArrayRefOfMyCharOrDigit
    /];
    use MooseX::Types::Moose qw/ArrayRef Str Int/;

    subtype MyChar, as Str, where {
    length == 1
    };

    subtype MyDigit, as Int, where {
    length == 1
    };

    coerce ArrayRef[MyChar|MyDigit], from Str, via {
    [split //]
    };

# same thing with an explicit subtype
    subtype ArrayRefOfMyCharOrDigit, as ArrayRef[MyChar|MyDigit];

    coerce ArrayRefOfMyCharOrDigit, from Str, via {
    [split //]
    };
}

{
    BEGIN { TypeLib->import(qw/
    MyChar MyDigit ArrayRefOfMyCharOrDigit/
    ) };
    use MooseX::Types::Moose 'ArrayRef';

    my $parameterized = ArrayRef[MyChar|MyDigit];
    { local $::TODO = "see comments in MooseX::Types->create_arged_...";
      ::ok( $parameterized->has_coercion, 'coercion applied to parameterized type' );
    }

    my $subtype = ArrayRefOfMyCharOrDigit;
    ::ok( $subtype->has_coercion, 'coercion applied to subtype' );
}

done_testing();
