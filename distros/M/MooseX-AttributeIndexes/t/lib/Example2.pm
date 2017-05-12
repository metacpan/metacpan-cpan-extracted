package Example2;

# $Id:$
use Moose;

use MooseX::AttributeIndexes;
has 'foo_indexed' => (
  isa      => 'Str',
  required => 1,
  is       => 'rw',
  indexed  => sub { return "${_}2" },
);

has 'foo_primary' => (
  isa           => 'Str',
  required      => 1,
  is            => 'rw',
  primary_index => sub { return "${_}2" },
);

has 'foo_nothing' => (
  isa      => 'Str',
  required => 1,
  is       => 'rw',
);

1;

