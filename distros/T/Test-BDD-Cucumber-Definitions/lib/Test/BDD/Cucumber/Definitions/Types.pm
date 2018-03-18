package Test::BDD::Cucumber::Definitions::Types;

use strict;
use warnings;

use DDP ( show_unicode => 1 );
use MooseX::Types::Common::String qw(NonEmptyStr);
use MooseX::Types::Moose qw(Int Str RegexpRef);
use Test::BDD::Cucumber::Definitions qw(S);
use Test::More;
use Try::Tiny;

use MooseX::Types (
    -declare => [
        qw(
            TbcdInt
            TbcdStr
            TbcdNonEmptyStr
            TbcdRegexpRef
            )
    ]
);

our $VERSION = '0.26';

# Interpolation of variables (scenario and environment)
sub _interpolate {
    my ($value) = @_;

    my $orig = $value;

    # Scenario variables
    my $is = $value =~ s/ S\{ (.+?) \} /
        S->{var}->{scenario}->{vars}->{$1} || '';
     /gxe;

    # Environment variables
    my $ie = $value =~ s/ \$\{ (.+?) \} /
        $ENV{$1} || '';
    /gxe;

    if ( $is || $ie ) {
        diag( sprintf( q{Inteprolated value "%s" = %s}, $orig, np $value) );
    }

    return $value;
}

# TbcdInt
subtype(
    TbcdInt,
    as Int,
    message {
        qq{"$_" is not a valid TBCD Int}
    }
);

coerce(
    TbcdInt,
    from Str,
    via { _interpolate $_}
);

# TbcdStr
subtype(
    TbcdStr,
    as Str,
    message {
        qq{"$_" is not a valid TBCD Str}
    }
);

coerce(
    TbcdStr,
    from Str,
    via { _interpolate $_}
);

# TbcdNonEmptyStr
subtype(
    TbcdNonEmptyStr,
    as NonEmptyStr,
    message {
        qq{"$_" is not a valid TBCD NonEmptyStr}
    }
);

coerce(
    TbcdNonEmptyStr,
    from NonEmptyStr,
    via { _interpolate $_}
);

# TbcdRegexpRef
subtype(
    TbcdRegexpRef,
    as RegexpRef,
    message {
        qq{"$_" is not a valid TBCD TbcdRegexpRef}
    }
);

coerce(
    TbcdRegexpRef,
    from Str,
    via {
        my $value = _interpolate $_;

        try {
            qr/$value/;    ## no critic [RegularExpressions::RequireExtendedFormatting]
        }
        catch {
            return $value;
        };
    }
);

1;
