package Test::BDD::Cucumber::Definitions::JSON::In;

use strict;
use warnings;

use Test::BDD::Cucumber::StepFile qw(Given When Then);
use Test::BDD::Cucumber::Definitions::JSON qw(:util);

our $VERSION = '0.14';

## no critic [RegularExpressions::ProhibitCaptureWithoutTest]
## no critic [RegularExpressions::RequireExtendedFormatting]

# http response content decode JSON
When qr/http response content decode JSON/, sub {
    content_decode();
};

1;
