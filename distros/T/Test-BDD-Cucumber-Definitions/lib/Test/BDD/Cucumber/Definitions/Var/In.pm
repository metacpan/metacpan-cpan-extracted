package Test::BDD::Cucumber::Definitions::Var::In;

use strict;
use warnings;
use utf8;

use Test::BDD::Cucumber::Definitions qw(C Given When Then);
use Test::BDD::Cucumber::Definitions::Var qw(:util);

our $VERSION = '0.34';

## no critic [RegularExpressions::ProhibitCaptureWithoutTest]
## no critic [RegularExpressions::RequireExtendedFormatting]
## no critic [RegularExpressions::ProhibitComplexRegexes]

sub import {

    #       var scenario var "(.+?)" set "(.*)"
    When qr/var scenario var "(.+?)" set "(.*)"/, sub {
        var_scenario_var_set( $1, $2 );
    };

    #       var scenario var "(.+?)" random "(.*)"
    When qr/var scenario var "(.+?)" random "(.*)"/, sub {
        var_scenario_var_random( $1, $2 );
    };

    return;
}

1;
