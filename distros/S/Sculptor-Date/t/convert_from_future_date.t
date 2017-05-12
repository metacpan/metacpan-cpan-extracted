#!perl -T

use Test::More tests => 2;
use Sculptor::Date qw/date_to_number/;

is( date_to_number('2100-01-01'), 766645 );
is( date_to_number('2550-06-12'), 931166 );
