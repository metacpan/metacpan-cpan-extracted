package Test::BDD::Cucumber::Definitions::Struct::In;

use strict;
use warnings;
use utf8;

use Test::BDD::Cucumber::Definitions qw(Given When Then);
use Test::BDD::Cucumber::Definitions::Struct qw(Struct);

our $VERSION = '0.41';

## no critic [RegularExpressions::ProhibitCaptureWithoutTest]
## no critic [RegularExpressions::RequireExtendedFormatting]
## no critic [RegularExpressions::ProhibitComplexRegexes]

sub import {

    #        read http response content as JSON
    Given qr/read http response content as JSON/, sub {
        Struct->read_http_response_content_as_json();
    };

    #        read file content as JSON
    Given qr/read file content as JSON/, sub {
        Struct->read_file_content_as_json();
    };

    #        read zip archive members as list
    Given qr/read zip archive members as list/, sub {
        Struct->read_zip_archive_members_as_list();
    };

    #        read base response as struct
    Given qr/read base response as struct/, sub {
        Struct->read_base_response_as_struct();
    };

    #       struct data element "(.+?)" eq "(.*)"
    Then qr/struct data element "(.+?)" eq "(.*)"/, sub {
        Struct->data_element_eq( $1, $2 );
    };

    #       struct data list "(.+?)" any eq "(.*)"
    Then qr/struct data list "(.+?)" any eq "(.*)"/, sub {
        Struct->data_list_any_eq( $1, $2 );
    };

    #       struct data element "(.+?)" re "(.*)"
    Then qr/struct data element "(.+?)" re "(.*)"/, sub {
        Struct->data_element_re( $1, $2 );
    };

    #       struct data list "(.+?)" any re "(.*)"
    Then qr/struct data list "(.+?)" any re "(.*)"/, sub {
        Struct->data_list_any_re( $1, $2 );
    };

    #       struct data list "(.+?)" count "(.*)"
    Then qr/struct data list "(.+?)" count "(.*)"/, sub {
        Struct->data_list_count( $1, $2 );
    };

    #       struct data element "(.+?)" key "(.*)"
    Then qr/struct data element "(.+?)" key "(.*)"/, sub {
        Struct->data_element_key( $1, $2 );
    };

    #       struct data list "(.+?)" all key "(.*)"
    Then qr/struct data list "(.+?)" all key "(.*)"/, sub {
        Struct->data_list_all_key( $1, $2 );
    };

    return;
}

1;
