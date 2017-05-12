#!perl -T

use Test::More tests => 2;
use Sculptor::Date qw/number_to_date/;

is(number_to_date(999999),'2738-11-27');
is(number_to_date(800000),'2191-04-29');
