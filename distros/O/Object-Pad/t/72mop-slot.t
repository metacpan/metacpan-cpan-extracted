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
is( $slotmeta->class->name, "Example", '$slotmeta->class gives class' );
is( $slotmeta->param_name, undef, '$slotmeta->param_name' );
ok( !$slotmeta->has_param, '$slotmeta->has_param' );

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

# $slotmeta->param
{
   class WithParam {
      has $name :param;
   }

   my $slotmeta = Object::Pad::MOP::Class->for_class( "WithParam" )
      ->get_slot( '$name' );

   is( $slotmeta->name, '$name', '$slotmeta->name for param' );
   is( $slotmeta->param_name, 'name', '$slotmeta->param_name for param' );
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
