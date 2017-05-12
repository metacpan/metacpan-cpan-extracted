#!perl -T

use Test::More tests => 2;
use Sculptor::Date qw/number_to_date/;

is(number_to_date(719162),'1969-12-31');
is(number_to_date(1),'0001-01-01');
