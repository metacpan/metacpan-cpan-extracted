package Test::BDD::Cucumber::Definitions::Zip::In;

use strict;
use warnings;

use Test::BDD::Cucumber::Definitions qw(Given When Then);
use Test::BDD::Cucumber::Definitions::Zip qw(:util);

our $VERSION = '0.19';

## no critic [RegularExpressions::ProhibitCaptureWithoutTest]
## no critic [RegularExpressions::RequireExtendedFormatting]

# http response content read Zip
When qr/http response content read Zip/, sub {
    read_content();
};

1;
