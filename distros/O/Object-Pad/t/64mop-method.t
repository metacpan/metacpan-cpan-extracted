#!/usr/bin/perl

use v5.18;
use warnings;

use Test2::V0;

use Object::Pad 0.800 ':experimental(mop)';

class Example {
   method m { }
}

my $classmeta = Object::Pad::MOP::Class->for_class( "Example" );

my $methodmeta = $classmeta->get_direct_method( 'm' );

is( $methodmeta->name, "m", '$methodmeta->name' );
is( $methodmeta->class->name, "Example", '$methodmeta->class gives class' );
ok( !$methodmeta->is_common, '$methodmeta->is_common' );

is( $classmeta->get_method( 'm' )->name, "m", '$classmeta->get_method' );

is( [ $classmeta->direct_methods ], [ $methodmeta ],
   '$classmeta->direct_methods' );

is( [ $classmeta->all_methods ], [ $methodmeta ],
   '$classmeta->all_methods' );

# should croak and not segfault
like( dies { $classmeta->get_direct_method( 'ZZZ' ) },
   qr/^Class Example does not have a method called 'ZZZ' at /,
   'Failure message for ->get_direct_method missing' );

class SubClass { inherit Example; }

ok( defined Object::Pad::MOP::Class->for_class( "SubClass" )->get_method( 'm' ),
   'Subclass can ->get_method' );

# subclass with overridden method
{
   class WithOverride {
      inherit Example;
      method m { "different" }
   }

   my @methodmetas = Object::Pad::MOP::Class->for_class( "WithOverride" )->all_methods;

   is( scalar @methodmetas, 1, 'overridden method is not duplicated' );
}

# :common methods
{
   class BClass {
      method cm :common { }
   }

   my $classmeta = Object::Pad::MOP::Class->for_class( "BClass" );

   my $methodmeta = $classmeta->get_direct_method( 'cm' );

   is( $methodmeta->name, "cm", '$methodmeta->name for :common' );
   is( $methodmeta->class->name, "BClass", '$methodmeta->class gives class for :common' );
   ok( $methodmeta->is_common, '$methodmeta->is_common for :common' );
}

# lexical methods should not appear in the MOP
{
   class CClass {
      my method lexmeth { return "OK" }
   }

   my $classmeta = Object::Pad::MOP::Class->for_class( "CClass" );

   ok( dies { $classmeta->get_direct_method( 'lexmeth' ) },
      'lexical method is not visible via MOP' );
}

done_testing;
