package Test::BDD::Cucumber::Definitions::File::In;

use strict;
use warnings;
use utf8;

use Test::BDD::Cucumber::Definitions qw(Given When Then);
use Test::BDD::Cucumber::Definitions::File qw(File);

our $VERSION = '0.41';

## no critic [RegularExpressions::ProhibitCaptureWithoutTest]
## no critic [RegularExpressions::RequireExtendedFormatting]
## no critic [RegularExpressions::ProhibitComplexRegexes]

sub import {

    #        file path set "(.*)"
    Given qr/file path set "(.*)"/, sub {
        File->path_set($1);
    };

    #       file read text "(.*)"
    When qr/file read text "(.*)"/, sub {
        File->read_text($1);
    };

    #       file read binary
    When qr/file read binary/, sub {
        File->read_binary();
    };

    #       file exists
    Then qr/file exists/, sub {
        File->exists_yes();
    };

    #       file not exists
    Then qr/file not exists/, sub {
        File->exists_no();
    };

    #       file type is "(.*)"
    Then qr/file type is "(.*)"/, sub {
        File->type_is($1);
    };

    return;
}

1;
