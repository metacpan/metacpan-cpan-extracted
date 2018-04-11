package Test::BDD::Cucumber::Definitions::Zip::In;

use strict;
use warnings;
use utf8;

use Test::BDD::Cucumber::Definitions qw(Given When Then);
use Test::BDD::Cucumber::Definitions::Zip qw(Zip);

our $VERSION = '0.34';

## no critic [RegularExpressions::ProhibitCaptureWithoutTest]
## no critic [RegularExpressions::RequireExtendedFormatting]
## no critic [RegularExpressions::ProhibitComplexRegexes]

sub import {

    #        read http response content as Zip
    Given qr/read http response content as Zip/, sub {
        Zip->read_http_response_content_as_zip();
    };

    return;
}

1;
