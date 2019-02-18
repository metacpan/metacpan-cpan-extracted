#!/usr/bin/env perl

use v5.14;
use warnings FATAL => qw(all);

use Test2::V0 -target => 'Term::Table2';

use Term::Table2;

my $expected = [
  '+-------+-------+-------+',
  '| Col.  | Col.  | Col.  |',
  '| No 1  | No 2  | No 3  |',
  '+-------+-------+-------+',
  '|       |       |       |',
  '+-------+-------+-------+',
];
my %params = (
  header       => ['Col. No 1', 'Col. No 2', 'Col. No 3'],
  column_width => 5,
  page_height  => 0,
  table_width  => 0,
);

is($CLASS->new(%params, rows => [['', '', '']]) ->fetch_all(), $expected, 'Array reference supplied');
is($CLASS->new(%params, rows => \&getTableLines)->fetch_all(), $expected, 'Code reference supplied');

done_testing();

sub getTableLines {
  state $table = [['', '', '']];
  return shift(@$table);
}