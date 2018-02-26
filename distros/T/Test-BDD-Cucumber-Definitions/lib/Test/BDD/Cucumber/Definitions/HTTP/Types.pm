package Test::BDD::Cucumber::Definitions::HTTP::Types;

use strict;
use warnings;

use MooseX::Types::Common::String qw(NonEmptyStr);
use MooseX::Types::Moose qw(Str Int RegexpRef);
use Try::Tiny;

use MooseX::Types (
    -declare => [
        qw(
            HttpHeader
            HttpMethod
            HttpUrl
            HttpCode
            HttpString
            HttpRegexp
            )
    ]
);

our $VERSION = '0.19';

subtype(
    HttpHeader,
    as NonEmptyStr,
    message {
        qq{"$_" is not a valid HTTP header}
    }
);

subtype(
    HttpMethod,
    as NonEmptyStr,
    message {
        qq{"$_" is not a valid HTTP method}
    }
);

subtype(
    HttpUrl,
    as NonEmptyStr,
    message {
        qq{"$_" is not a valid HTTP url}
    }
);

coerce(
    HttpUrl,
    from Str,
    via {
        my $value = $_;

        $value =~ s/\$\{ (.+?) \}/$ENV{$1} || ''/gxe;

        return $value;
    }
);

subtype(
    HttpCode,
    as Int,
    message {
        qq{"$_" is not a valid HTTP code}
    }
);

subtype(
    HttpString,
    as Str,
    message {
        qq{"$_" is not a valid HTTP string}
    }
);

subtype(
    HttpRegexp,
    as RegexpRef,
    message {
        qq{"$_" is not a valid HTTP regexp}
    }
);

coerce(
    HttpRegexp,
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
