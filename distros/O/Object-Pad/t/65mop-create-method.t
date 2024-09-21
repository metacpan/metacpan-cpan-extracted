#!/usr/bin/perl

use v5.18;
use warnings;

use Test2::V0;

use Object::Pad 0.800 ':experimental(mop)';

class AClass {
   use Test2::V0;

   BEGIN {
      # Most of this test has to happen at BEGIN time before AClass gets
      # sealed
      my $classmeta = Object::Pad::MOP::Class->for_caller;

      my $methodmeta = $classmeta->add_method( 'method', sub {
         return "result";
      } );

      is( $methodmeta->name, "method", '$methodmeta->name' );

      like( dies { $classmeta->add_method( undef, sub {} ) },
         qr/^methodname must not be undefined or empty /,
         'Failure from ->add_method undef' );
      like( dies { $classmeta->add_method( "", sub {} ) },
         qr/^methodname must not be undefined or empty /,
         'Failure from ->add_method on empty string' );

      like( dies { $classmeta->add_method( 'method', sub {} ) },
         qr/^Cannot add another method named method /,
         'Failure from ->add_method duplicate' );

      {
         'magic' =~ m/^(.*)$/;
         my $methodmeta = $classmeta->add_method( $1, sub {} );
         'different' =~ m/^(.*)$/;
         is( $methodmeta->name, 'magic', '->add_method captures FETCH magic' );
      }

      $classmeta->add_method( 'cmethod', common => 1, sub {
         return "Classy result";
      } );
   }
}

{
   my $obj = AClass->new;
   is( $obj->method, "result", '->method works' );

   my $can = $obj->can('method');
   is( ref($can), 'CODE', '->can("method") returns coderef' );
   is( $obj->$can, 'result', '... which works' );
}

# common method
{
   is( AClass->cmethod, "Classy result", '->cmethod works' );
}

done_testing;
