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
    _maxColumnWidth => sub { return 1 },
    _prepareRow     => sub { return \@header },
    _setLineFormat  => sub { return },
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

  @header                     = ('line');
  $table->{'broad_row'}       = WRAP;
  $table->{':separatingLine'} = '+-----+';
  $expected                   = {
    ':headerLines'    => ['+-----+', 'line', '+-----+'],
    ':linesPerPage'   => 8,
    ':linesPerRow'    => 2,
    ':separatingLine' => '+-----+',
    'broad_row'       => WRAP,
    'column_width'    => [1, 1, 2],
    'current_row'     => 0,
    'pad'             => [1, 1, 1],
    'page_height'     => 9,
    'table_width'     => 5,
  };
  is($table->_init(), $expected, 'Wrapped rows, header exists');

  @header                     = ();
  $table->{'broad_row'}       = CUT;
  $table->{':separatingLine'} = '+---+';
  delete($table->{'page_height'});
  delete($table->{'table_width'});
  $expected                   = {
    ':headerLines'    => [],
    ':linesPerPage'   => BIG_INT + 1,
    ':linesPerRow'    => 1,
    ':separatingLine' => '+---+',
    'broad_row'       => CUT,
    'column_width'    => [1, 1, 2],
    'current_row'     => 0,
    'pad'             => [1, 1, 1],
    'page_height'     => BIG_INT,
    'table_width'     => BIG_INT,
  };
  is($table->_init(), $expected, 'Unwrapped rows, no header');
};

subtest 'Failure' => sub {
  $table->{'page_height'}     = 9;
  $table->{'table_width'}     = 5;

  $table->{'pad'}             = [4, 4, 4];
  like(dies{$table->_init()}, qr/is lower than the width of the narrowest possible column/, 'Table is not wide enough');

  @header                     = ('line');
  $table->{'broad_row'}       = WRAP;
  $table->{'pad'}             = [1, 1, 1];
  $table->{'page_height'}     = 1;
  $table->{':separatingLine'} = '+-----+';
  like(dies{$table->_init()}, qr/is lower than the minimum possible page height/, 'Page is not high enough');
};

done_testing();