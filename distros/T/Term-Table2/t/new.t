#!/usr/bin/env perl

use v5.14;
use warnings FATAL => qw(all);

package Term::Table2;

use Test2::V0 -target => 'Term::Table2';
use Test2::Mock;

my $mockThis = Test2::Mock->new(
  class    => $CLASS,
  override => [
    _copy_options => sub { return $_[0] },
    _init         => sub { return $_[0] },
    _set_defaults => sub { return $_[0] },
    _validate     => sub {
      my ($self, $param) = @_;
      my %param          = @$param;
      $self->{'rows'}    = $param{'rows'};
      return $self;
    },
  ]
);

my $expected = bless(
  {
    ':end_of_chunk'      => FALSE,
    ':header_lines'      => [],
    ':line_format'       => '|',
    ':line_on_page'      => 0,
    ':lines_per_page'    => 1,
    ':lines_per_row'     => 1,
    ':number_of_columns' => undef,
    ':row_buffer'        => [],
    ':row_lines'         => [],
    ':separating_added'  => FALSE,
    ':separating_line'   => '+',
    ':split_offset'      => 0,
    ':total_width'       => 0,
    'current_row'        => 0,
    'end_of_table'       => FALSE,
  },
  $CLASS
);

$expected->{'rows'} = [];
is($CLASS->new('rows' => []), $expected, 'Source is array');

$expected->{'rows'} = {};
is($CLASS->new('rows' => {}), $expected, 'Source is function');

done_testing();