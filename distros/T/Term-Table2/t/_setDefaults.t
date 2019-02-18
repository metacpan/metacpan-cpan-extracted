#!/usr/bin/env perl

use v5.14;
use warnings FATAL => 'all';

package Term::Table2;

use Clone qw(clone);
use Test2::V0 -target => 'Term::Table2';
use Test2::Mock;

my $mockThis = Test2::Mock->new(
  class    => $CLASS,
  override => [
    GetTerminalSize => sub { return (20, 10) },
  ]
);

my $table;
my $expected;

$table    = bless({':numberOfColumns' => 2}, $CLASS);
$expected = bless(
  {
    ':numberOfColumns' => 2,
    'broad_column'     => [WRAP, WRAP],
    'broad_header'     => [WRAP, WRAP],
    'broad_row'        => WRAP,
    'collapse'         => [FALSE, FALSE],
    'column_width'     => [ADJUST, ADJUST],
    'header'           => [],
    'pad'              => 1,
    'page_height'      => 10,
    'rows'             => [],
    'separate_rows'    => FALSE,
    'table_width'      => 20,
  },
  $CLASS,
);
is($table->_setDefaults(), $expected, 'No option supplied');

$table = bless(
  {
    ':numberOfColumns' => 2,
    'broad_column'     => CUT,
    'broad_header'     => [CUT, WRAP],
    'broad_row'        => SPLIT,
    'collapse'         => [FALSE, TRUE],
    'column_width'     => [ADJUST, 10],
    'pad'              => 2,
    'page_height'      => 30,
    'rows'             => [],
    'separate_rows'    => FALSE,
    'table_width'      => 40,
  },
  $CLASS,
);
$expected                   = clone($table);
$expected->{'broad_column'} = [CUT, CUT];
$expected->{'header'}       = [];
$expected->{'rows'}         = [];
is($table->_setDefaults(), $expected, 'All option supplied');

done_testing();