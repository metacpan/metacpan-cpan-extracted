#!/usr/bin/perl

use v5.18;
use warnings;

use Test2::V0;

use Object::Pad 0.800 ':experimental(mop)';

role TheRole
{
   method m {}
}

{
   class AClass {
      BEGIN {
         Object::Pad::MOP::Class->for_caller->compose_role( "TheRole" );
      }
   }

   my $ameta = Object::Pad::MOP::Class->for_class( "AClass" );

   is( [ map { $_->name } $ameta->direct_roles ], [qw( TheRole )],
      'AClass meta ->direct_roles' );
   can_ok( AClass->new, qw( m ) );
}

{
   class BClass {
      BEGIN {
         Object::Pad::MOP::Class->for_caller->compose_role(
            Object::Pad::MOP::Class->for_class( "TheRole" )
         );
      }
   }

   my $bmeta = Object::Pad::MOP::Class->for_class( "BClass" );

   is( [ map { $_->name } $bmeta->direct_roles ], [qw( TheRole )],
      'BClass meta ->direct_roles' );
   can_ok( BClass->new, qw( m ) );
}

done_testing;
