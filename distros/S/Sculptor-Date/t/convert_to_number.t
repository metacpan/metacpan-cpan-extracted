#!perl -T

use Test::More tests => 2;
use Sculptor::Date qw/date_to_number/;

is( 719163, date_to_number('1970-01-01') );
is( 740000, date_to_number('2027-01-19') );
