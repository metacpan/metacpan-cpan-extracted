#!/usr/bin/env perl

use v5.14;
use warnings FATAL => qw(all);

package Term::Table2;

use Test2::V0 -target => 'Term::Table2';
use Test2::Mock;

my @header;
my $mockThis = Test2::Mock->new(
  class    => $CLASS,
  override => [
    _max_column_width => sub { return 1 },
    _prepare_row      => sub { return \@header },
    _set_line_format  => sub { return },
  ]
);
my $table = bless(
  {
    'column_width' => [0, 0, 2],
    'pad'          => 1,
    'page_height'  => 9,
    'table_width'  => 5,
  },
  $CLASS,
);

subtest 'Success' => sub {
  my $expected;

  @header                      = ('line');
  $table->{'broad_row'}        = WRAP;
  $table->{':separating_line'} = '+-----+';
  $expected                    = {
    ':header_lines'    => ['+-----+', 'line', '+-----+'],
    ':lines_per_page'  => 8,
    ':lines_per_row'   => 2,
    ':separating_line' => '+-----+',
    'broad_row'        => WRAP,
    'column_width'     => [1, 1, 2],
    'current_row'      => 0,
    'pad'              => [1, 1, 1],
    'page_height'      => 9,
    'table_width'      => 5,
  };
  is($table->_init(), $expected, 'Wrapped rows, header exists');

  @header                      = ();
  $table->{'broad_row'}        = CUT;
  $table->{':separating_line'} = '+---+';
  delete($table->{'page_height'});
  delete($table->{'table_width'});
  $expected                   = {
    ':header_lines'    => [],
    ':lines_per_page'  => BIG_INT,
    ':lines_per_row'   => 1,
    ':separating_line' => '+---+',
    'broad_row'        => CUT,
    'column_width'     => [1, 1, 2],
    'current_row'      => 0,
    'pad'              => [1, 1, 1],
    'page_height'      => BIG_INT,
    'table_width'      => BIG_INT,
  };
  is($table->_init(), $expected, 'Unwrapped rows, no header');
};

subtest 'Failure' => sub {
  $table->{'page_height'}      = 9;
  $table->{'table_width'}      = 5;

  $table->{'pad'}              = [4, 4, 4];
  like(dies{$table->_init()}, qr/is lower than the width of the narrowest possible column/, 'Table is not wide enough');

  @header                      = ('line');
  $table->{'broad_row'}        = WRAP;
  $table->{'pad'}              = [1, 1, 1];
  $table->{'page_height'}      = 1;
  $table->{':separating_line'} = '+-----+';
  like(dies{$table->_init()}, qr/is lower than the minimum possible page height/, 'Page is not high enough');
};

done_testing();