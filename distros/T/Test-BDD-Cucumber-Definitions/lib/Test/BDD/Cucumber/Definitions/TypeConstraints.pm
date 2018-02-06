package Test::BDD::Cucumber::Definitions::TypeConstraints;

use strict;
use warnings;

use Moose::Util::TypeConstraints;
use Try::Tiny;

our $VERSION = '0.08';

subtype(
    'ValueString',
    as 'Str',
    message {qq{"$_" is not a valid string}}
);

subtype(
    'ValueInteger',
    as 'Int',
    message {qq{"$_" is not a valid integer}}
);

subtype(
    'ValueRegexp',
    as 'RegexpRef',
    message {qq{"$_" is not a valid regexp}}
);

coerce(
    'ValueRegexp',
    from 'Str',
    via {
        my $value = $_;

        try {
            qr/$value/;    ## no critic [RegularExpressions::RequireExtendedFormatting]
        }
        catch {
            return $value;
        }
    }
);

subtype(
    'ValueJsonpath',
    as 'Str',
    message {qq{"$_" is not a valid jsonpath}}
);

1;
