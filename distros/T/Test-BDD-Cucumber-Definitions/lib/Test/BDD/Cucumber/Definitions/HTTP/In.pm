package Test::BDD::Cucumber::Definitions::HTTP::In;

use strict;
use warnings;
use utf8;

use Test::BDD::Cucumber::Definitions qw(C Given When Then);
use Test::BDD::Cucumber::Definitions::HTTP qw(HTTP);

our $VERSION = '0.40';

## no critic [RegularExpressions::ProhibitCaptureWithoutTest]
## no critic [RegularExpressions::RequireExtendedFormatting]
## no critic [RegularExpressions::ProhibitComplexRegexes]

sub import {

    #        http request header "(.+?)" set "(.*)"
    Given qr/http request header "(.+?)" set "(.*)"/, sub {
        HTTP->request_header_set( $1, $2 );
    };

    #        http request content set
    Given qr/http request content set/, sub {
        HTTP->request_content_set( C->data() );
    };

    #       http request "(.+?)" send "(.+)"
    When qr/http request "(.+?)" send "(.+)"/, sub {
        HTTP->request_send( $1, $2 );
    };

    #       http response code eq "(.+)"
    Then qr/http response code eq "(.+)"/, sub {
        HTTP->response_code_eq($1);
    };

    #       http response header "(.+?)" eq "(.*)"
    Then qr/http response header "(.+?)" eq "(.*)"/, sub {
        HTTP->response_header_eq( $1, $2 );
    };

    #       http response header "(.+?)" re "(.+)"
    Then qr/http response header "(.+?)" re "(.+)"/, sub {
        HTTP->response_header_re( $1, $2 );
    };

    #       http response content eq "(.*)"
    Then qr/http response content eq "(.*)"/, sub {
        HTTP->response_content_eq($1);
    };

    #       http response content re "(.+)"
    Then qr/http response content re "(.+)"/, sub {
        HTTP->response_content_re($1);
    };

    return;
}

1;
