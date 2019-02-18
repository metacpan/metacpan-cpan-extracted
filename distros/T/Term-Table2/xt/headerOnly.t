#!/usr/bin/env perl

use v5.14;
use warnings FATAL => qw(all);

use Test2::V0 -target => 'Term::Table2';

use Term::Table2;

my $table = $CLASS->new(
  header       => ['Col. No 1', 'Col. No 2', 'Col. No 3'],
  rows         => [],
  column_width => 5,
  page_height  => 0,
  table_width  => 0,
);
is($table->fetch_all(), [], 'No rows - no output');

done_testing();