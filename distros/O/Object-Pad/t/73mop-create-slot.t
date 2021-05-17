#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Object::Pad;

class AClass {
   use Test::More;
   use Test::Fatal;

   BEGIN {
      # Most of this test has to happen at BEGIN time before AClass gets
      # sealed
      my $classmeta = Object::Pad::MOP::Class->for_caller;

      my $slotmeta = $classmeta->add_slot( '$slot' );

      is( $slotmeta->name, "\$slot", '$slotmeta->name' );

      like( exception { $classmeta->add_slot( undef ) },
         qr/^slotname must not be undefined or empty /,
         'Failure from ->add_slot undef' );
      like( exception { $classmeta->add_slot( "" ) },
         qr/^slotname must not be undefined or empty /,
         'Failure from ->add_slot on empty string' );

      like( exception { $classmeta->add_slot( "foo" ) },
         qr/^slotname must begin with a sigil /,
         'Failure from ->add_slot without sigil' );

      like( exception { $classmeta->add_slot( '$slot' ) },
         qr/^Cannot add another slot named \$slot /,
         'Failure from ->add_slot duplicate' );

      ok( *slot = eval( 'method :lvalue { $slot }' ),
         'Can compile method with lexical $slot' );

      my $anonslot = $classmeta->add_slot( '$' );
      *anonslot = sub :lvalue { $anonslot->value( shift ) };

      ok( !exception { $classmeta->add_slot( '$' ) },
         'Can add a second anonymous slot' );

      {
         '$magic' =~ m/^(.*)$/;
         my $slotmeta = $classmeta->add_slot( $1 );
         'different' =~ m/^(.*)$/;
         is( $slotmeta->name, '$magic', '->add_slot captures FETCH magic' );
      }
   }
}

{
   my $obj = AClass->new;
   $obj->slot = 10;
   is( $obj->slot, 10, '->slot accessor works' );

   $obj->anonslot = 20;
   is( $obj->anonslot, 20, '->anonslot accessor works' );
}

done_testing;
