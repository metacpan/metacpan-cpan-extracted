#!perl -T

use Test::More tests => 2;
use Sculptor::Date qw/number_to_date/;

is(number_to_date(719163),'1970-01-01');
is(number_to_date(740000),'2027-01-19');
