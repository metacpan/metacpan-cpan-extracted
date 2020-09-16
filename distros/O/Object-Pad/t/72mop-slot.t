#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;
use Test::Fatal;

use Object::Pad;

class Example {
   has $slot;
   method slot :lvalue { $slot }
}

my $classmeta = Example->META;

my $slotmeta = $classmeta->get_slot( '$slot' );

is( $slotmeta->name, "\$slot", '$slotmeta->name' );
is( $slotmeta->class->name, "Example", '$slotmeta->class gives class' );

# $slotmeta->value as accessor
{
   my $obj = Example->new;
   $obj->slot = "the value";

   is( $slotmeta->value( $obj ), "the value",
      '$slotmeta->value as accessor' );
}

# $slotmeta->value as mutator
{
   my $obj = Example->new;

   $slotmeta->value( $obj ) = "a new value";

   is( $obj->slot, "a new value",
      '$obj->slot after $slotmeta->value as mutator' );
}

# Forbid writing to non-scalar slots via ->value
{
   class List {
      has @values;
   }

   my $arrayslotmeta = List->META->get_slot( '@values' );

   like( exception { no warnings; $arrayslotmeta->value( List->new ) = [] },
      qr/^Modification of a read-only value attempted at /,
      'Attempt to set value of list slot fails' );

   my $e;
   ok( !defined( $e = exception { @{ $arrayslotmeta->value( List->new ) } = (1,2,3) } ),
      '->value accessor still works fine' ) or
      diag( "Exception was $e" );
}

done_testing;
