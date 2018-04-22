package Test::BDD::Cucumber::Definitions::Var::In;

use strict;
use warnings;
use utf8;

use Test::BDD::Cucumber::Definitions qw(C Given When Then);
use Test::BDD::Cucumber::Definitions::Var qw(Var);

our $VERSION = '0.38';

## no critic [RegularExpressions::ProhibitCaptureWithoutTest]
## no critic [RegularExpressions::RequireExtendedFormatting]
## no critic [RegularExpressions::ProhibitComplexRegexes]

sub import {

    #        var scenario var "(.+?)" set "(.*)"
    Given qr/var scenario var "(.+?)" set "(.*)"/, sub {
        Var->scenario_var_set( $1, $2 );
    };

    #        var scenario var "(.+?)" random "(.*)"
    Given qr/var scenario var "(.+?)" random "(.*)"/, sub {
        Var->scenario_var_random( $1, $2 );
    };

    return;
}

1;
