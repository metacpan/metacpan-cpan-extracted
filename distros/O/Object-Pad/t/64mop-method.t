#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;
use Test::Fatal;

use Object::Pad ':experimental(mop)';

class Example {
   method m { }
}

my $classmeta = Object::Pad::MOP::Class->for_class( "Example" );

my $methodmeta = $classmeta->get_direct_method( 'm' );

is( $methodmeta->name, "m", '$methodmeta->name' );
is( $methodmeta->class->name, "Example", '$methodmeta->class gives class' );
ok( !$methodmeta->is_common, '$methodmeta->is_common' );

is( $classmeta->get_method( 'm' )->name, "m", '$classmeta->get_method' );

is_deeply( [ $classmeta->direct_methods ], [ $methodmeta ],
   '$classmeta->direct_methods' );

is_deeply( [ $classmeta->all_methods ], [ $methodmeta ],
   '$classmeta->all_methods' );

class SubClass :isa(Example) {}

ok( defined Object::Pad::MOP::Class->for_class( "SubClass" )->get_method( 'm' ),
   'Subclass can ->get_method' );

# subclass with overridden method
{
   class WithOverride :isa(Example) {
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

done_testing;
