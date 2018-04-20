package Test::BDD::Cucumber::Definitions::Base::In;

use strict;
use warnings;
use utf8;

use Test::BDD::Cucumber::Definitions qw(C Given When Then);
use Test::BDD::Cucumber::Definitions::Base qw(Base);

our $VERSION = '0.37';

## no critic [RegularExpressions::ProhibitCaptureWithoutTest]
## no critic [RegularExpressions::RequireExtendedFormatting]
## no critic [RegularExpressions::ProhibitComplexRegexes]

sub import {

    #        base param "(.+?)" set "(.*)"
    Given qr/base param "(.+?)" set "(.*)"/, sub {
        Base->param_set( $1, $2 );
    };

    #       base request send "(.+?)"
    When qr/base request send "(.+?)"/, sub {
        Base->request_send($1);
    };

    #       base request send
    When qr/base request send/, sub {
        Base->request_send( C->data() );
    };

    return;
}

1;
