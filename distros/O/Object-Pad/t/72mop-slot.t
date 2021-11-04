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

my $classmeta = Object::Pad::MOP::Class->for_class( "Example" );

my $slotmeta = $classmeta->get_slot( '$slot' );

is( $slotmeta->name, "\$slot", '$slotmeta->name' );
is( $slotmeta->sigil, "\$", '$slotmeta->sigil' );
is( $slotmeta->class->name, "Example", '$slotmeta->class gives class' );

is_deeply( [ $classmeta->slots ], [ $slotmeta ],
   '$classmeta->slots' );

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

# slotmeta on roles (RT138927)
{
   role ARole {
      has $data = 42;
   }

   my $slotmeta = Object::Pad::MOP::Class->for_class( 'ARole' )->get_slot( '$data' );
   is( $slotmeta->name, '$data', '$slotmeta->name for slot of role' );

   class AClass does ARole {
      has $data = 21;
   }

   my $obja = AClass->new;
   is( $slotmeta->value( $obja ), 42,
      '$slotmeta->value as accessor on role instance fetches correct slot' );

   class BClass isa AClass {
      has $data = 63;
   }

   my $objb = BClass->new;
   is( $slotmeta->value( $objb ), 42,
      '$slotmeta->value as accessor on role instance subclass fetches correct slot' );
}

# RT136869
{
   class A {
      has @arr;
      BUILD { @arr = (1,2,3) }
      method m { @arr }
   }
   role R {
      has $data :param;
   }
   class B isa A does R {}

   is_deeply( [ B->new( data => 456 )->m ], [ 1, 2, 3 ],
      'Role params are embedded correctly' );
}

# Forbid writing to non-scalar slots via ->value
{
   class List {
      has @values;
   }

   my $arrayslotmeta = Object::Pad::MOP::Class->for_class( "List" )
      ->get_slot( '@values' );

   like( exception { no warnings; $arrayslotmeta->value( List->new ) = [] },
      qr/^Modification of a read-only value attempted at /,
      'Attempt to set value of list slot fails' );

   my $e;
   ok( !defined( $e = exception { @{ $arrayslotmeta->value( List->new ) } = (1,2,3) } ),
      '->value accessor still works fine' ) or
      diag( "Exception was $e" );
}

done_testing;
