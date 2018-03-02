package Test::BDD::Cucumber::Definitions::Types;

use strict;
use warnings;

use MooseX::Types::Common::String qw(NonEmptyStr);
use MooseX::Types::Moose qw(Int Str RegexpRef);
use Test::BDD::Cucumber::Definitions qw(S);
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

our $VERSION = '0.21';

# TbcdInt
subtype(
    TbcdInt,
    as Int,
    message {
        qq{"$_" is not a valid TBCD Int}
    }
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
    via {
        my $value = $_;

        $value =~ s/S\{ (.+?) \}/S->{var}->{scenario}->{vars}->{$1} || ''/gxe;

        return $value;
    }
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
    via {
        my $value = $_;

        $value =~ s/S\{ (.+?) \}/S->{var}->{scenario}->{vars}->{$1} || ''/gxe;

        return $value;
    }
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
        my $value = $_;

        try {
            qr/$value/;    ## no critic [RegularExpressions::RequireExtendedFormatting]
        }
        catch {
            return $value;
        };
    }
);

1;
