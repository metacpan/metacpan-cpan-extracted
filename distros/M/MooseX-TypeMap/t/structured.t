
use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  eval q[
   use MooseX::Types::Structured;  1;
  ] or plan skip_all => 'requires MooseX::Types::Structured';
}

plan tests => 1;

use MooseX::TypeMap;
use MooseX::TypeMap::Entry;
use MooseX::Types::Structured qw/Tuple Dict/;
use MooseX::Types::Moose ( qw(Str Int Num Item Value ClassName RoleName) );

my $type_map = MooseX::TypeMap->new(
  entries => [
    MooseX::TypeMap::Entry->new(
      data => 'int tuple',
      type_constraint => Tuple[Tuple[ Int, Int ], Dict[]],
    ),
  ],
  subtype_entries => [
    MooseX::TypeMap::Entry->new(
      data => 'rolename tuple',
      type_constraint => Tuple[Tuple[ RoleName, RoleName ], Dict[]],
    ),
    MooseX::TypeMap::Entry->new(
      data => 'classname tuple',
      type_constraint => Tuple[Tuple[ ClassName, ClassName ], Dict[]],
    ),
    MooseX::TypeMap::Entry->new(
      data => 'classname-str tuple',
      type_constraint => Tuple[Tuple[ ClassName, Str ], Dict[]],
    ),
    MooseX::TypeMap::Entry->new(
      data => 'item tuple',
      type_constraint => Tuple[Tuple[ Item, Item ], Dict[]],
    ),
    MooseX::TypeMap::Entry->new(
      data => 'str tuple',
      type_constraint => Tuple[Tuple[ Str, Str ], Dict[]],
    ),
    MooseX::TypeMap::Entry->new(
      data => 'value tuple',
      type_constraint => Tuple[Tuple[ Value, Value ], Dict[]],
    ),
  ],
);

my @entries;
for my $slot ( $type_map->_sorted_entries ){
  push(@entries, [map { $_->data } @$slot] );
}

my @correct_order = map { [ $_ ] } 'rolename tuple', 'classname tuple',
  'classname-str tuple', 'str tuple', 'value tuple', 'item tuple';
is_deeply(\@entries, \@correct_order, 'correct sorted order');
