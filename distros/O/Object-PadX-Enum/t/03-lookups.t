#!perl
use v5.22;
use warnings;

use Test2::V0;

use Object::PadX::Enum;

enum Suits {
   item CLUBS;
   item DIAMONDS;
   item HEARTS;
   item SPADES;
}

is(
   [ map { $_->ordinal } Suits->values ],
   [ 0, 1, 2, 3 ],
   'values returns singletons in declaration order',
);

ok( Suits->from_ordinal(0) == Suits->CLUBS,    'from_ordinal(0) is CLUBS' );
ok( Suits->from_ordinal(3) == Suits->SPADES,   'from_ordinal(3) is SPADES' );
is( Suits->from_ordinal(99), undef,            'from_ordinal out of range is undef' );
is( Suits->from_ordinal(-1), undef,            'from_ordinal negative is undef' );

ok( Suits->from_name('HEARTS')   == Suits->HEARTS, 'from_name HEARTS' );
ok( Suits->from_name('DIAMONDS') == Suits->DIAMONDS, 'from_name DIAMONDS' );
is( Suits->from_name('SPOONS'),  undef, 'unknown from_name is undef' );

# Empty enum is legal.
enum Empty { }

is( [ Empty->values ], [], 'empty enum: values returns nothing' );

done_testing;
