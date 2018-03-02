package Test::BDD::Cucumber::Definitions::Struct::In;

use strict;
use warnings;

use Test::BDD::Cucumber::Definitions qw(Given When Then);
use Test::BDD::Cucumber::Definitions::Struct qw(:util);

our $VERSION = '0.21';

## no critic [RegularExpressions::ProhibitCaptureWithoutTest]
## no critic [RegularExpressions::RequireExtendedFormatting]

# http response content read JSON
When qr/http response content read JSON/, sub {
    read_content();
};

# struct data element "" eq ""
Then qr/struct data element "(.+?)" eq "(.*)"/, sub {
    my ( $jsonpath, $value ) = ( $1, $2 );

    jsonpath_eq( $jsonpath, $value );
};

# struct data element "" re ""
Then qr/struct data element "(.+?)" re "(.+)"/, sub {
    my ( $jsonpath, $value ) = ( $1, $2 );

    jsonpath_re( $jsonpath, $value );
};

1;
