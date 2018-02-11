package Test::BDD::Cucumber::Definitions::Data::In;

use strict;
use warnings;

use Test::BDD::Cucumber::StepFile qw(Given When Then);
use Test::BDD::Cucumber::Definitions::Data qw(:util);

our $VERSION = '0.11';

## no critic [RegularExpressions::ProhibitCaptureWithoutTest]
## no critic [RegularExpressions::RequireExtendedFormatting]

# Decode http response content
When qr/http response content decode as "(.+)"/, sub {
    my ($format) = ($1);

    content_decode($format);
};

Then qr/data structure jsonpath "(.+?)" must be "(.+)"/, sub {
    my ( $jsonpath, $value ) = ( $1, $2 );

    jsonpath_eq( $jsonpath, $value );
};

Then qr/data structure jsonpath "(.+?)" must be like "(.+)"/, sub {
    my ( $jsonpath, $value ) = ( $1, $2 );

    jsonpath_re( $jsonpath, $value );
};

1;
