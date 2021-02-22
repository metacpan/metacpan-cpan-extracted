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
         __PACKAGE__->META->compose_role( "TheRole" );
      }
   }

   is_deeply( [ map { $_->name } AClass->META->roles ], [qw( TheRole )],
      'AClass->META->roles' );
   can_ok( AClass->new, qw( m ) );
}

{
   class BClass {
      BEGIN {
         __PACKAGE__->META->compose_role( TheRole->META );
      }
   }

   is_deeply( [ map { $_->name } BClass->META->roles ], [qw( TheRole )],
      'BClass->META->roles' );
   can_ok( BClass->new, qw( m ) );
}

done_testing;
