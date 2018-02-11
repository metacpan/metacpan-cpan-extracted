package Test::BDD::Cucumber::Definitions::Data::Ru;

use strict;
use warnings;
use utf8;

use Test::BDD::Cucumber::StepFile qw(Given When Then);
use Test::BDD::Cucumber::Definitions::Data qw(:util);

our $VERSION = '0.11';

## no critic [RegularExpressions::ProhibitCaptureWithoutTest]
## no critic [RegularExpressions::RequireExtendedFormatting]

When qr/в HTTP-ответе содержится валидный "(.+)"/, sub {
    my ($format) = ($1);

    content_decode($format);
};

Then qr/элемент данных "(.+?)" имеет значение "(.+)"/, sub {
    my ( $jsonpath, $value ) = ( $1, $2 );

    jsonpath_eq( $jsonpath, $value );
};

Then qr/элемент данных "(.+?)" совпадает с "(.+)"/, sub {
    my ( $jsonpath, $value ) = ( $1, $2 );

    jsonpath_re( $jsonpath, $value );
};

1;
