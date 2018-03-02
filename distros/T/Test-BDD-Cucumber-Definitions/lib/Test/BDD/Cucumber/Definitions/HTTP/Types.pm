package Test::BDD::Cucumber::Definitions::HTTP::Types;

use strict;
use warnings;

use MooseX::Types::Common::String qw(NonEmptyStr);
use MooseX::Types::Moose qw(Str Int RegexpRef);
use Test::BDD::Cucumber::Definitions qw(S);

use MooseX::Types (
    -declare => [
        qw(
            HttpHeader
            HttpMethod
            HttpUrl
            HttpCode
            )
    ]
);

our $VERSION = '0.21';

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

1;
