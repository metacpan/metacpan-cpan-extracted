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
    _getNextLines => sub { return },
  ]
);

my $table = bless({}, $CLASS);

subtest 'End of table' => sub {
  $table->{'end_of_table'} = TRUE;
  $table->{':rowLines'}    = [];
  is($table->fetch(), undef, 'Reached');
};

subtest 'Next row' => sub {
  my $expected;

  $table->{'end_of_table'}   = TRUE;
  $table->{':lineOnPage'}    = 0;
  $table->{':rowLines'}      = ['line1', 'line2'];
  $table->{':linesPerPage'}  = 2;
  $expected = clone($table);
  $expected->{':lineOnPage'} = 1;
  $expected->{':rowLines'}   = ['line2'];
  is($table->fetch(), 'line1',   'First line on page, end of page not reached, row not exhausted (line content)');
  is($table,          $expected, 'First line on page, end of page not reached, row not exhausted (line counter)');

  $table->{'end_of_table'}   = FALSE;
  $table->{':lineOnPage'}    = 1;
  $table->{':rowLines'}      = [];
  $table->{':linesPerPage'}  = 2;
  $expected = clone($table);
  $expected->{':lineOnPage'} = 0;
  $expected->{':rowBuffer'}  = [];
  $expected->{':rowLines'}   = [];
  is($table->fetch(), undef,     'Row exhausted, not the first line on page, end of page reached (line content)');
  is($table,          $expected, 'Row exhausted, not the first line on page, end of page reached (line counter)');

  $table->{'end_of_table'}   = FALSE;
  $table->{':lineOnPage'}    = 1;
  $table->{':rowLines'}      = ['line'];
  $table->{':linesPerPage'}  = 3;
  $expected = clone($table);
  $expected->{':lineOnPage'} = 2;
  $expected->{':rowBuffer'}  = [];
  $expected->{':rowLines'}   = [];
  is($table->fetch(), 'line',    'Row not exhausted, not the first line on page (line content)');
  is($table,          $expected, 'Row not exhausted, not the first line on page (line counter)');
};

done_testing();