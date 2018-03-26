package Test::BDD::Cucumber::Definitions::HTTP::In;

use strict;
use warnings;
use utf8;

use Test::BDD::Cucumber::Definitions qw(C Given When Then);
use Test::BDD::Cucumber::Definitions::HTTP qw(:util);

our $VERSION = '0.29';

## no critic [RegularExpressions::ProhibitCaptureWithoutTest]
## no critic [RegularExpressions::RequireExtendedFormatting]
## no critic [RegularExpressions::ProhibitComplexRegexes]

sub import {

    #       http request header "(.+?)" set "(.*)"
    When qr/http request header "(.+?)" set "(.*)"/, sub {
        http_request_header_set( $1, $2 );
    };

    #       http request content set
    When qr/http request content set/, sub {
        http_request_content_set( C->data() );
    };

    #       http request "(.+?)" send "(.+)"
    When qr/http request "(.+?)" send "(.+)"/, sub {
        http_request_send( $1, $2 );
    };

    #       http response code eq "(.+)"
    Then qr/http response code eq "(.+)"/, sub {
        http_response_code_eq($1);
    };

    #       http response header "(.+?)" eq "(.*)"
    Then qr/http response header "(.+?)" eq "(.*)"/, sub {
        http_response_header_eq( $1, $2 );
    };

    #       http response header "(.+?)" re "(.+)"
    Then qr/http response header "(.+?)" re "(.+)"/, sub {
        http_response_header_re( $1, $2 );
    };

    #       http response content eq "(.*)"
    Then qr/http response content eq "(.*)"/, sub {
        http_response_content_eq($1);
    };

    #       http response content re "(.+)"
    Then qr/http response content re "(.+)"/, sub {
        http_response_content_re($1);
    };

    return;
}

1;
