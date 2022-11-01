#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Object::Pad ':experimental(adjust_params)';

{
   my %captured;

   class WithAdjustParams {
      ADJUST :params ( :$x, :$y = "default Y" )
      {
         $captured{x} = $x;
         $captured{y} = $y;
      }
   }

   undef %captured;
   WithAdjustParams->new( x => "the X", y => "the Y" );
   is_deeply( \%captured, { x => "the X", y => "the Y" }, 'ADJUST :params saw x and y' );

   undef %captured;
   WithAdjustParams->new( x => "the X" );
   is_deeply( \%captured, { x => "the X", y => "default Y" }, 'ADJUST :params saw x and default y' );

   my $LINE = __LINE__+1;
   ok( !defined eval { WithAdjustParams->new(); 1 }, 'Missing required parameter throws exception' );
   like( $@, qr/^Required parameter 'x' is missing for WithAdjustParams constructor at \S+ line $LINE\./,
      'Exception thrown from constructor with missing parameter' );
}

{
   class StrictlyWithParams :strict(params) {
      # Check that a trailing comma is permitted
      ADJUST :params ( :$param = undef, ) { }
   }

   ok( defined eval { StrictlyWithParams->new( param => 123 ) }, ':strict(params) is OK' )
      or diag( "Exception was: $@" );
   ok( !defined eval { StrictlyWithParams->new( more => 2 ) }, ':strict(params) complains about others' );
}

{
   my %captured;

   class WithRestParams {
      ADJUST :params ( :$one = 1, :$two = 2, %params ) {
         %captured = %params;
      }
   }

   undef %captured;
   WithRestParams->new( one => 111, three => 3 );
   is_deeply( \%captured, { three => 3 }, 'ADJUST :params rest views remaining params' );
}

{
   my %captured;

   class StrictlyWithRestParams :strict(params) {
      ADJUST :params ( %params ) {
         %captured = %params; %params = ();
      }
   }

   StrictlyWithRestParams->new( unknown => "OK" );
   is_deeply( \%captured, { unknown => "OK" }, 'ADJUST :params rest can consume params' );
}

{
   class ExpressionOrder {
      field $val;
      ADJUST :params (
         :$first = undef,
         :$second = uc $first,
      ) {
         $val = $second;
      }
      method val { return $val; }
   }

   is( ExpressionOrder->new( first => "value" )->val, "VALUE",
      'Named param expressions are evaluated in order' );
}

done_testing;
