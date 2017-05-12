use strict;
use warnings;
use Test::More tests=>11;

{
    package TypeLib;
    use MooseX::Types::Structured qw(Dict Tuple);
    use MooseX::Types::Moose qw(Int Str Item);
    use MooseX::Types -declare => [qw(
        MyDict1 MyDict2  MyDict4
    )];

    subtype MyDict1,
    as Dict[name=>Str, age=>Int];

    subtype MyDict2,
    as Dict[name=>Str, age=>Int];

     subtype MyDict4,
    as Dict[name=>Str, age=>Item];

}

BEGIN {
    TypeLib->import(':all');
}

use Moose::Util::TypeConstraints;
use MooseX::Types::Structured qw(Dict Tuple);
use MooseX::Types::Moose qw(Item Any);


ok ( MyDict2->is_a_type_of(MyDict4),
  'MyDict2 is_a_type_of MyDict4');

ok ( MyDict1->is_subtype_of(MyDict4),
  'MyDict1 is_subtype_of MyDict4');

ok ( (Tuple[Tuple[ class_type('Paper'), class_type('Stone') ], Dict[]])->is_a_type_of( Tuple[Tuple[ Item, Item ], Dict[]] ),
  "tuple of tuple" );

ok ( (Tuple[Tuple[ class_type('Paper'), class_type('Stone') ], Dict[]])->is_a_type_of( Tuple[Tuple[ Item, Item ], Dict[]] ),
  "tuple of tuple" );

ok ( (Tuple[Tuple[ class_type('Paper'), class_type('Stone') ], Dict[]])->is_subtype_of( Tuple[Tuple[ Item, Item ], Dict[]] ),
  "tuple of tuple" );

my $item = subtype as 'Item';

ok ( $item->is_subtype_of('Any'),
  q[$item is subtype of 'Any']);

ok ( Item->is_subtype_of('Any'),
  q[Item is subtype of 'Any']);

ok ( $item->is_subtype_of(Any),
  q[Item is subtype of Any]);

ok ( Item->is_subtype_of(Any),
  q[Item is subtype of Any]);

my $any = subtype as 'Any';

ok ( ! $item->is_subtype_of($any),
  q[$item is NOT a subtype of $any]);

ok ( ! Item->is_subtype_of($any),
  q[Item is NOT a subtype of $any]);
