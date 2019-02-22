#!/usr/bin/env perl

use v5.14;
use warnings FATAL => qw(all);

package Term::Table2;

use Clone qw(clone);
use Test2::V0 -target => 'Term::Table2';
use Test2::Mock;

my $mockThis = Test2::Mock->new(
  class    => $CLASS,
  override => [
    _get_next_lines => sub { return },
  ]
);

my $table = bless({}, $CLASS);

subtest 'End of table' => sub {
  $table->{'end_of_table'} = TRUE;
  $table->{':row_lines'}   = [];
  is($table->fetch(), undef, 'Reached');
};

subtest 'Next row' => sub {
  my $expected;

  $table->{'end_of_table'}     = TRUE;
  $table->{':line_on_page'}    = 0;
  $table->{':row_lines'}       = ['line1', 'line2'];
  $table->{':lines_per_page'}  = 2;
  $expected = clone($table);
  $expected->{':line_on_page'} = 1;
  $expected->{':row_lines'}    = ['line2'];
  is($table->fetch(), 'line1',   'First line on page, end of page not reached, row not exhausted (line content)');
  is($table,          $expected, 'First line on page, end of page not reached, row not exhausted (line counter)');

  $table->{'end_of_table'}     = FALSE;
  $table->{':line_on_page'}    = 1;
  $table->{':row_lines'}       = [];
  $table->{':lines_per_page'}  = 2;
  $expected = clone($table);
  $expected->{':line_on_page'} = 0;
  $expected->{':row_buffer'}   = [];
  $expected->{':row_lines'}    = [];
  is($table->fetch(), undef,     'Row exhausted, not the first line on page, end of page reached (line content)');
  is($table,          $expected, 'Row exhausted, not the first line on page, end of page reached (line counter)');

  $table->{'end_of_table'}     = FALSE;
  $table->{':line_on_page'}    = 1;
  $table->{':row_lines'}       = ['line'];
  $table->{':lines_per_page'}  = 3;
  $expected = clone($table);
  $expected->{':line_on_page'} = 2;
  $expected->{':row_buffer'}   = [];
  $expected->{':row_lines'}    = [];
  is($table->fetch(), 'line',    'Row not exhausted, not the first line on page (line content)');
  is($table,          $expected, 'Row not exhausted, not the first line on page (line counter)');
};

done_testing();