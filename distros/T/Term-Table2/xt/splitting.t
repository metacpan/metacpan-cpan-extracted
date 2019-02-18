#!/usr/bin/env perl

use v5.14;
use warnings FATAL => qw(all);

use Test2::V0 -target => 'Term::Table2';

use Term::Table2 qw (CUT SPLIT WRAP);

my $expected;
my $header;
my @rows;
my %params;

$expected = [
  '+-------+-------',
  '| Col.  | Col.  ',
  '| No 1  | No 2  ',
  '+-------+-------',
  '| Value | Value ',
  '|  0.1  |  0.2  ',
  '| Value | Value ',
  '|  1.1  |  1.2  ',
  '| Value | Value ',
  '|  2.1  |  2.2  ',
  '| Value | Value ',
  '|  3.1  |  3.2  ',
  '| Value | Value ',
  '|  4.1  |  4.2  ',
  '| Value | Value ',
  '|  5.1  |  5.2  ',
  '| Value | Value ',
  '|  6.1  |  6.2  ',
  '| Value | Value ',
  '|  7.1  |  7.2  ',
  '+-------+-------',
  '+-------+',
  '| Col.  |',
  '| No 3  |',
  '+-------+',
  '| Value |',
  '|  0.3  |',
  '| Value |',
  '|  1.3  |',
  '| Value |',
  '|  2.3  |',
  '| Value |',
  '|  3.3  |',
  '| Value |',
  '|  4.3  |',
  '| Value |',
  '|  5.3  |',
  '| Value |',
  '|  6.3  |',
  '| Value |',
  '|  7.3  |',
  '+-------+',
];
$header = ['Col. No 1', 'Col. No 2', 'Col. No 3'];
# @rows   = map {["Value $_.1", "Value $_.2", "Value $_.3"]} 0 .. 1;
@rows   = map {["Value $_.1", "Value $_.2", "Value $_.3"]} 0 .. 7;
%params = (
  header       => $header,
  broad_row    => SPLIT,
  column_width =>  5,
  page_height  =>  0,
  table_width  => 16,
);
is($CLASS->new(%params, rows => \@rows)->fetch_all(), $expected, 'Wrapped cell content');

$expected = [
  '+-----------+-----------+-----------+',
  '| Col. No 1 | Col. No 2 | Col. No 3 |',
  '+-----------+-----------+-----------+',
  '| Value 0.1 | Value 0.2 | Value 0.3 |',
  '| Value 1.1 | Value 1.2 | Value 1.3 |',
  '| Value 2.1 | Value 2.2 | Value 2.3 |',
  '| Value 3.1 | Value 3.2 | Value 3.3 |',
  '| Value 4.1 | Value 4.2 | Value 4.3 |',

  '+-----------+-----------+-----------+',
  '| Col. No 1 | Col. No 2 | Col. No 3 |',
  '+-----------+-----------+-----------+',
  '| Value 5.1 | Value 5.2 | Value 5.3 |',
  '| Value 6.1 | Value 6.2 | Value 6.3 |',
  '| Value 7.1 | Value 7.2 | Value 7.3 |',
  '+-----------+-----------+-----------+',
];
%params = (
  header       => $header,
  column_width => 9,
  page_height  => 8,
  table_width  => 0,
);
is($CLASS->new(%params, rows => \@rows)->fetch_all(), $expected, 'Cell content unwrapped, some lines on the final page');

$expected = [
  '+-----------+-------',
  '----+-----------+',
  '| Col. No 1 | Col. N',
  'o 2 | Col. No 3 |',
  '+-----------+-------',
  '----+-----------+',
  '| Value 0.1 | Value',
  '0.2 | Value 0.3 |',
  '| Value 1.1 | Value',
  '1.2 | Value 1.3 |',
  '| Value 2.1 | Value',
  '2.2 | Value 2.3 |',
  '| Value 3.1 | Value',
  '3.2 | Value 3.3 |',

  '+-----------+-------',
  '----+-----------+',
  '| Col. No 1 | Col. N',
  'o 2 | Col. No 3 |',
  '+-----------+-------',
  '----+-----------+',
  '| Value 4.1 | Value',
  '4.2 | Value 4.3 |',
  '| Value 5.1 | Value',
  '5.2 | Value 5.3 |',
  '| Value 6.1 | Value',
  '6.2 | Value 6.3 |',
  '| Value 7.1 | Value',
  '7.2 | Value 7.3 |',

  '+-----------+-------',
  '----+-----------+',
  '| Col. No 1 | Col. N',
  'o 2 | Col. No 3 |',
  '+-----------+-------',
  '----+-----------+',
  '+-----------+-------',
  '----+-----------+',
];
%params = (
  header       => $header,
  column_width =>  9,
  page_height  => 15,
  table_width  => 20,
);
is($CLASS->new(%params, rows => \@rows)->fetch_all(), $expected, 'Lines wrapped, nothing but footer on the final page');

done_testing();