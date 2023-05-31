use lib 'lib';
use lib '../lib';
use 5.006;
use strict;
use warnings;
use Test::More tests => 5;
use Perlmazing;

my $scalar = 'This is a string';
my $hashref = {
	day          => 17,
	hour         => 14,
	is_leap_year => 1,
	isdst        => 0,
	minute       => 34,
	month        => "02",
	second       => "12.9713640",
	wday         => 3,
	yday         => 47,
	year         => 2016,
};
my %hash = %$hashref;
my $arrayref = [sort 1..100];
my @array = @$arrayref;

is dumped($scalar), '"This is a string"', 'scalar';
is dumped($hashref), '{
  day          => 17,
  hour         => 14,
  is_leap_year => 1,
  isdst        => 0,
  minute       => 34,
  month        => "02",
  second       => "12.9713640",
  wday         => 3,
  yday         => 47,
  year         => 2016,
}', 'hashref';
is dumped(sort %hash), '(
  0,
  "02",
  1,
  "12.9713640",
  14,
  17,
  2016,
  3,
  34,
  47,
  "day",
  "hour",
  "is_leap_year",
  "isdst",
  "minute",
  "month",
  "second",
  "wday",
  "yday",
  "year",
)', 'hash';
is dumped($arrayref), '[
  1,
  10,
  100,
  11 .. 19,
  2,
  20 .. 29,
  3,
  30 .. 39,
  4,
  40 .. 49,
  5,
  50 .. 59,
  6,
  60 .. 69,
  7,
  70 .. 79,
  8,
  80 .. 89,
  9,
  90 .. 99,
]', 'arrayref';
is dumped(@array), '(
  1,
  10,
  100,
  11 .. 19,
  2,
  20 .. 29,
  3,
  30 .. 39,
  4,
  40 .. 49,
  5,
  50 .. 59,
  6,
  60 .. 69,
  7,
  70 .. 79,
  8,
  80 .. 89,
  9,
  90 .. 99,
)', 'array';