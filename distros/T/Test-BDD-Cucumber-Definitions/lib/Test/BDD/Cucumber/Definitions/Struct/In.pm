package Test::BDD::Cucumber::Definitions::Struct::In;

use strict;
use warnings;

use Test::BDD::Cucumber::StepFile qw(Given When Then);
use Test::BDD::Cucumber::Definitions::Struct qw(:util);

our $VERSION = '0.14';

## no critic [RegularExpressions::ProhibitCaptureWithoutTest]
## no critic [RegularExpressions::RequireExtendedFormatting]

# data structure jsonpath "" eq ""
Then qr/data structure jsonpath "(.+?)" eq "(.+)"/, sub {
    my ( $jsonpath, $value ) = ( $1, $2 );

    jsonpath_eq( $jsonpath, $value );
};

# data structure jsonpath "" re ""
Then qr/data structure jsonpath "(.+?)" re "(.+)"/, sub {
    my ( $jsonpath, $value ) = ( $1, $2 );

    jsonpath_re( $jsonpath, $value );
};

1;
