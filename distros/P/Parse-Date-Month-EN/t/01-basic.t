#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Parse::Date::Month::EN qw(parse_date_month_en);

is_deeply(parse_date_month_en(text=>"sep"), 9);
is_deeply(parse_date_month_en(text=>"Jun"), 6);
is_deeply(parse_date_month_en(text=>"SEP"), 9);
is_deeply(parse_date_month_en(text=>"sept"), 9);
is_deeply(parse_date_month_en(text=>"mars"), undef);

DONE_TESTING:
done_testing();
