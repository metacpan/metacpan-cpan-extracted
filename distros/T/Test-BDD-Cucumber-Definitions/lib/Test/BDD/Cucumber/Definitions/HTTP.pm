package Test::BDD::Cucumber::Definitions::HTTP;

use strict;
use warnings;

use Test::BDD::Cucumber::StepFile qw(Given When Then);
use Test::BDD::Cucumber::Definitions::HTTP::Util qw(S C);

our $VERSION = '0.02';

## no critic [RegularExpressions::ProhibitCaptureWithoutTest]
## no critic [RegularExpressions::RequireExtendedFormatting]

# Set http request header
When qr/http request header "(.+?)" is set to "(.+)"/, sub {
    my ( $header, $value ) = ( $1, $2 );

    Test::BDD::Cucumber::Definitions::HTTP::Util::header_set( $header, $value );
};

# Set http request content
When qr/http request content is set to/, sub {
    my ($content) = C->data();

    Test::BDD::Cucumber::Definitions::HTTP::Util::content_set($content);
};

# Send request
When qr/http request "(.+?)" to "(.+)"/, sub {
    my ( $method, $url ) = ( $1, $2 );

    Test::BDD::Cucumber::Definitions::HTTP::Util::request_send( $method, $url );
};

# Check http response code
Then qr/http response code must be "(.+)"/, sub {
    my ($code) = ($1);

    Test::BDD::Cucumber::Definitions::HTTP::Util::code_eq($code);
};

# Check http response header
Then qr/http response header "(.+)" must be like "(.+)"/, sub {
    my ( $name, $value ) = ( $1, $2 );

    Test::BDD::Cucumber::Definitions::HTTP::Util::header_re( $name, $value );
};

# Check http response content
Then qr/http response content must be like "(.+)"/, sub {
    my ($value) = ($1);

    Test::BDD::Cucumber::Definitions::HTTP::Util::content_re($value);
};

# Decode http response content
Then qr/http response content must be decoded as "(.+)"/, sub {
    my ($format) = ($1);

    Test::BDD::Cucumber::Definitions::HTTP::Util::content_decode($format);
};

1;
