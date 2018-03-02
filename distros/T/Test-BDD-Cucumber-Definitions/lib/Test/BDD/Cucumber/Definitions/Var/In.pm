package Test::BDD::Cucumber::Definitions::Var::In;

use strict;
use warnings;
use utf8;

use Test::BDD::Cucumber::Definitions qw(C Given When Then);
use Test::BDD::Cucumber::Definitions::Var qw(:util);

our $VERSION = '0.21';

## no critic [RegularExpressions::ProhibitCaptureWithoutTest]
## no critic [RegularExpressions::RequireExtendedFormatting]
## no critic [RegularExpressions::ProhibitComplexRegexes]

# var scenario var "" set ""
When qr/var scenario var "(.+?)" set "(.*)"/, sub {
    my ( $name, $value ) = ( $1, $2 );

    var_scenario_var_set( $name, $value );
};

# var scenario var "" random ""
When qr/var scenario var "(.+?)" random "(.*)"/, sub {
    my ( $name, $value ) = ( $1, $2 );

    var_scenario_var_random( $name, $value );
};

1;
