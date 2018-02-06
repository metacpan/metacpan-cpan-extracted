package Test::BDD::Cucumber::Definitions::HTTP;

use strict;
use warnings;

use Test::BDD::Cucumber::StepFile qw(Given When Then);
use Test::BDD::Cucumber::Definitions::HTTP::Util qw(C :util);

our $VERSION = '0.08';

## no critic [RegularExpressions::ProhibitCaptureWithoutTest]
## no critic [RegularExpressions::RequireExtendedFormatting]

# Set http request header
When qr/http request header "(.+?)" is set to "(.+)"/, sub {
    my ( $header, $value ) = ( $1, $2 );

    header_set( $header, $value );
};

# Set http request content
When qr/http request content is set to/, sub {
    my ($content) = C->data();

    content_set($content);
};

# Send request
When qr/http request "(.+?)" to "(.+)"/, sub {
    my ( $method, $url ) = ( $1, $2 );

    request_send( $method, $url );
};

# Check http response code
Then qr/http response code must be "(.+)"/, sub {
    my ($code) = ($1);

    code_eq($code);
};

# Check http response header
Then qr/http response header "(.+)" must be like "(.+)"/, sub {
    my ( $name, $value ) = ( $1, $2 );

    header_re( $name, $value );
};

# Check http response header
Then qr/http response header "(.+)" must be "(.+)"/, sub {
    my ( $name, $value ) = ( $1, $2 );

    header_eq( $name, $value );
};

# Check http response content
Then qr/http response content must be "(.+)"/, sub {
    my ($value) = ($1);

    content_eq($value);
};

# Check http response content
Then qr/http response content must be like "(.+)"/, sub {
    my ($value) = ($1);

    content_re($value);
};

Then qr/http response decoded content must be "(.+)"/, sub {
    my ($value) = ($1);

    content_eq_decoded($value);
};

Then qr/http response decoded content must be like "(.+)"/, sub {
    my ($value) = ($1);

    content_re_decoded($value);
};

1;
