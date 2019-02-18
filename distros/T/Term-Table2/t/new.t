#!/usr/bin/env perl

use v5.14;
use warnings FATAL => qw(all);

package Term::Table2;

use Test2::V0 -target => 'Term::Table2';
use Test2::Mock;

my $mockThis = Test2::Mock->new(
  class    => $CLASS,
  override => [
    _copyOptions => sub { return $_[0] },
    _init        => sub { return $_[0] },
    _setDefaults => sub { return $_[0] },
    _validate    => sub {
      my ($self, $param) = @_;
      my %param          = @$param;
      $self->{'rows'}    = $param{'rows'};
      return $self;
    },
  ]
);

my $expected = bless(
  {
    ':endOfChunk'      => FALSE,
    ':headerLines'     => [],
    ':lineFormat'      => '|',
    ':lineOnPage'      => 0,
    ':linesPerPage'    => 1,
    ':linesPerRow'     => 1,
    ':numberOfColumns' => undef,
    ':rowBuffer'       => [],
    ':rowLines'        => [],
    ':separatingAdded' => FALSE,
    ':separatingLine'  => '+',
    ':splitOffset'     => 0,
    ':totalWidth'      => 0,
    'current_row'      => 0,
    'end_of_table'     => FALSE,
  },
  $CLASS
);

$expected->{'rows'} = [];
is($CLASS->new('rows' => []), $expected, 'Source is array');

$expected->{'rows'} = {};
is($CLASS->new('rows' => {}), $expected, 'Source is function');

done_testing();