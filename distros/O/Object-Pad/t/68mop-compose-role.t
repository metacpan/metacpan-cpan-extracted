#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Object::Pad;

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

   is_deeply( [ map { $_->name } $ameta->direct_roles ], [qw( TheRole )],
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

   is_deeply( [ map { $_->name } $bmeta->direct_roles ], [qw( TheRole )],
      'BClass meta ->direct_roles' );
   can_ok( BClass->new, qw( m ) );
}

done_testing;
