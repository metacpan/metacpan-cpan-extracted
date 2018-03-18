package Test::BDD::Cucumber::Definitions::Zip::In;

use strict;
use warnings;
use utf8;

use Test::BDD::Cucumber::Definitions qw(Given When Then);
use Test::BDD::Cucumber::Definitions::Zip qw(:util);

our $VERSION = '0.26';

## no critic [RegularExpressions::ProhibitCaptureWithoutTest]
## no critic [RegularExpressions::RequireExtendedFormatting]
## no critic [RegularExpressions::ProhibitComplexRegexes]

sub import {

    #       http response content read Zip
    When qr/http response content read Zip/, sub {
        http_response_content_read_zip();
    };

    return;
}

1;
