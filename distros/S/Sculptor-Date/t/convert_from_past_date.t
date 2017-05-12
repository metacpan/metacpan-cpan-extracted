#!perl -T

use Test::More tests => 2;
use Sculptor::Date qw/date_to_number/;

is( date_to_number('1066-10-13'), 389269 );
is( date_to_number('1776-07-04'), 648491 );
