use strict;
use warnings;

use Test::More 0.88;
use MooseX::Types;
use MooseX::Types::Moose qw(Any Item );


my $item = subtype as Item;

ok Item->equals('Item');
ok Item->equals(Item);

ok ( $item->is_subtype_of('Any'),
  q[$item is subtype of 'Any']);

ok ( Item->is_subtype_of('Any'),
  q[Item is subtype of 'Any']);

ok ( Item->is_subtype_of(Any),
  q[Item is subtype of Any]);

done_testing;
