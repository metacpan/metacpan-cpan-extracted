package Test::BDD::Cucumber::Definitions::Struct::Types;

use strict;
use warnings;

use MooseX::Types::Moose qw(Str RegexpRef);
use Try::Tiny;

use MooseX::Types (
    -declare => [
        qw(
            StructJsonpath
            StructString
            StructRegexp
            )
    ]
);

our $VERSION = '0.19';

subtype(
    StructJsonpath,
    as Str,
    message {
        qq{"$_" is not a valid Struct jsonpath}
    }
);

subtype(
    StructString,
    as Str,
    message {
        qq{"$_" is not a valid Struct string}
    }
);

subtype(
    StructRegexp,
    as RegexpRef,
    message {
        qq{"$_" is not a valid Struct regexp}
    }
);

coerce(
    StructRegexp,
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
