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

      my $methodmeta = $classmeta->add_method( 'method', sub {
         return "result";
      } );

      is( $methodmeta->name, "method", '$methodmeta->name' );

      like( exception { $classmeta->add_method( undef, sub {} ) },
         qr/^methodname must not be undefined or empty /,
         'Failure from ->add_method undef' );
      like( exception { $classmeta->add_method( "", sub {} ) },
         qr/^methodname must not be undefined or empty /,
         'Failure from ->add_method on empty string' );

      like( exception { $classmeta->add_method( 'method', sub {} ) },
         qr/^Cannot add another method named method /,
         'Failure from ->add_method duplicate' );

      {
         'magic' =~ m/^(.*)$/;
         my $methodmeta = $classmeta->add_method( $1, sub {} );
         'different' =~ m/^(.*)$/;
         is( $methodmeta->name, 'magic', '->add_method captures FETCH magic' );
      }
   }
}

{
   my $obj = AClass->new;
   is( $obj->method, "result", '->method works' );
}

done_testing;
