package Test::BDD::Cucumber::Definitions::Struct::In;

use strict;
use warnings;
use utf8;

use Test::BDD::Cucumber::Definitions qw(Given When Then);
use Test::BDD::Cucumber::Definitions::Struct qw(:util);

our $VERSION = '0.29';

## no critic [RegularExpressions::ProhibitCaptureWithoutTest]
## no critic [RegularExpressions::RequireExtendedFormatting]
## no critic [RegularExpressions::ProhibitComplexRegexes]

sub import {

    #       http response content read JSON
    When qr/http response content read JSON/, sub {
        http_response_content_read_json();
    };

    #       zip archive members read list
    When qr/zip archive members read list/, sub {
        zip_archive_members_read_list();
    };

    #       struct data element "(.+?)" eq "(.*)"
    Then qr/struct data element "(.+?)" eq "(.*)"/, sub {
        struct_data_element_eq( $1, $2 );
    };

    #       struct data array "(.+?)" any eq "(.*)"
    Then qr/struct data array "(.+?)" any eq "(.*)"/, sub {
        struct_data_array_any_eq( $1, $2 );
    };

    #       struct data element "(.+?)" re "(.*)"
    Then qr/struct data element "(.+?)" re "(.*)"/, sub {
        struct_data_element_re( $1, $2 );
    };

    #       struct data array "(.+?)" any re "(.*)"
    Then qr/struct data array "(.+?)" any re "(.*)"/, sub {
        struct_data_array_any_re( $1, $2 );
    };

    #       struct data array "(.+?)" count "(.*)"
    Then qr/struct data array "(.+?)" count "(.*)"/, sub {
        struct_data_array_count( $1, $2 );
    };

    return;
}

1;
