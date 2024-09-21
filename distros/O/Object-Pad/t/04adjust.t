#!/usr/bin/perl

use v5.18;
use warnings;

use Test2::V0;

use Object::Pad 0.800 ':experimental(adjust_params)';

{
   my %captured;

   class WithAdjustParams {
      ADJUST :params ( :$req, :$opt = "default opt" )
      {
         $captured{req} = $req;
         $captured{opt} = $opt;
      }
   }

   undef %captured;
   WithAdjustParams->new( req => "the req", opt => "the opt" );
   is( \%captured, { req => "the req", opt => "the opt" }, 'ADJUST :params saw req and opt' );

   undef %captured;
   WithAdjustParams->new( req => "the req" );
   is( \%captured, { req => "the req", opt => "default opt" }, 'ADJUST :params saw req and default opt' );

   my $LINE = __LINE__+1;
   ok( !defined eval { WithAdjustParams->new(); 1 }, 'Missing required parameter throws exception' );
   like( $@, qr/^Required parameter 'req' is missing for WithAdjustParams constructor at \S+ line $LINE\./,
      'Exception thrown from constructor with missing parameter' );
}

{
   my %captured;

   class WithAdjustParamsDefaults {
      ADJUST :params ( :$x = "default X", :$y //= "default Y", :$z ||= "default Z" )
      {
         $captured{x} = $x;
         $captured{y} = $y;
         $captured{z} = $z;
      }
   }

   undef %captured;
   WithAdjustParamsDefaults->new( x => "the X", y => "the Y", z => "the Z" );
   is( \%captured, { x => "the X", y => "the Y", z => "the Z" }, 'ADJUST :params saw passed values' );

   undef %captured;
   WithAdjustParamsDefaults->new();
   is( \%captured, { x => "default X", y => "default Y", z => "default Z" },
      'ADJUST :params saw defaults when absent' );

   undef %captured;
   WithAdjustParamsDefaults->new( x => undef, y => undef, z => undef );
   is( \%captured, { x => undef, y => "default Y", z => "default Z" },
      'ADJUST :params saw x undef but y z defaults when undef' );

   undef %captured;
   WithAdjustParamsDefaults->new( x => "", y => "", z => "" );
   is( \%captured, { x => "", y => "", z => "default Z" },
      'ADJUST :params saw x y "" but z defaults when ""' );
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
   is( \%captured, { three => 3 }, 'ADJUST :params rest views remaining params' );
}

{
   my %captured;

   class StrictlyWithRestParams :strict(params) {
      ADJUST :params ( %params ) {
         %captured = %params; %params = ();
      }
   }

   StrictlyWithRestParams->new( unknown => "OK" );
   is( \%captured, { unknown => "OK" }, 'ADJUST :params rest can consume params' );
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

# out-of-block control flow emits warnings
{
   my $warnings;
   BEGIN { $SIG{__WARN__} = sub { $warnings .= $_[0] }; }

   my $WARNLINE;

   class ReturnFromAdjust {
      $WARNLINE = __LINE__+1;
      ADJUST { return; }
   }

   BEGIN { undef $SIG{__WARN__} }

   like( $warnings,
      qr/^Using return to leave an ADJUST block is discouraged and will be removed in a later version at \S+ line $WARNLINE\./,
      'return from ADJUST emits warning' );
}

use Object::Pad ':experimental(composed_adjust)';

# class with composed ADJUST blocks
{
   class ComposedAdjust {
      field $adjusted;

      field $a = "a";
      ADJUST { $adjusted .= $a; }
      ADJUST { $adjusted .= "b"; }

      field $c = "c";
      ADJUST { $adjusted .= $c; }

      method result { $adjusted }
   }

   is( ComposedAdjust->new->result, "abc", 'Composed ADJUST blocks still work' );
}

# ADJUST :params can also be composed
{
   class ComposedAdjustParams {
      field $adjusted;
      ADJUST { $adjusted .= "a"; }
      ADJUST :params ( :$x ) { $adjusted .= $x; }
      ADJUST { $adjusted .= "c"; }
      method result { $adjusted }
   }

   is( ComposedAdjustParams->new( x => "X" )->result, "aXc", 'Composed ADJUST blocks permit :params' );
}

done_testing;
