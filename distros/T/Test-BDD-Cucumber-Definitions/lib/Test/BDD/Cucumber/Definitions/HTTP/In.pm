package Test::BDD::Cucumber::Definitions::HTTP::In;

use strict;
use warnings;

use Test::BDD::Cucumber::StepFile qw(Given When Then);
use Test::BDD::Cucumber::Definitions::HTTP qw(C :util);

our $VERSION = '0.14';

## no critic [RegularExpressions::ProhibitCaptureWithoutTest]
## no critic [RegularExpressions::RequireExtendedFormatting]

# http request header "" set ""
When qr/http request header "(.+?)" set "(.+)"/, sub {
    my ( $header, $value ) = ( $1, $2 );

    header_set( $header, $value );
};

# http request content set
When qr/http request content set/, sub {
    my ($content) = C->data();

    content_set($content);
};

# http request "" send ""
When qr/http request "(.+?)" send "(.+)"/, sub {
    my ( $method, $url ) = ( $1, $2 );

    request_send( $method, $url );
};

# http response code eq ""
Then qr/http response code eq "(.+)"/, sub {
    my ($code) = ($1);

    code_eq($code);
};

# http response header "" eq ""
Then qr/http response header "(.+?)" eq "(.+)"/, sub {
    my ( $name, $value ) = ( $1, $2 );

    header_eq( $name, $value );
};

# http response header "" re ""
Then qr/http response header "(.+?)" re "(.+)"/, sub {
    my ( $name, $value ) = ( $1, $2 );

    header_re( $name, $value );
};

# http response content eq ""
Then qr/http response content eq "(.+)"/, sub {
    my ($value) = ($1);

    content_eq($value);
};

# http response content re ""
Then qr/http response content re "(.+)"/, sub {
    my ($value) = ($1);

    content_re($value);
};

1;
