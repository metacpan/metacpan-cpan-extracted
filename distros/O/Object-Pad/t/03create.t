#!/usr/bin/perl

use v5.18;
use warnings;

use Test2::V0;

use Scalar::Util qw( reftype );

use Object::Pad 0.800;

class Point {
   field $x = 0;
   field $y = 0;

   BUILD {
      ( $x, $y ) = @_;
   }

   method where { sprintf "(%d,%d)", $x, $y }
}

{
   my $p = Point->new( 10, 20 );
   is( $p->where, "(10,20)", '$p->where' );
}

my @buildargs;
my @build;

class WithBuildargs {
   sub BUILDARGS {
      @buildargs = @_;
      return ( 4, 5, 6 );
   }

   BUILD {
      @build = @_;
   }
}

{
   WithBuildargs->new( 1, 2, 3 );

   is( \@buildargs, [qw( WithBuildargs 1 2 3 )], '@_ to BUILDARGS' );
   is( \@build,     [qw( 4 5 6 )],               '@_ to BUILD' );
}

{
   my @called;
   my $class_in_ADJUST;

   class WithAdjust {
      BUILD {
         push @called, "BUILD";
      }

      ADJUST {
         push @called, "ADJUST";
         $class_in_ADJUST = __CLASS__;
      }
   }

   WithAdjust->new;
   is( \@called, [qw( BUILD ADJUST )], 'ADJUST invoked after BUILD' );

   is( $class_in_ADJUST, "WithAdjust", '__CLASS__ during ADJUST block' )
}

{
   my $paramvalue;

   class StrictParams :strict(params) {
      ADJUSTPARAMS {
         my ($href) = @_;
         $paramvalue = delete $href->{param};
      }
   }

   StrictParams->new( param => "thevalue" );
   is( $paramvalue, "thevalue", 'ADJUSTPARAMS captured the value' );

   ok( !defined eval { StrictParams->new( unknown => "name" ) },
      ':strict(params) complains about unrecognised param' );
   like( $@, qr/^Unrecognised parameters for StrictParams constructor: 'unknown' at /,
      'message from unrecognised param to constructor' );
}

# RT140314
{
   class NoParamsAtAll :strict(params) { }

   ok( !defined eval { NoParamsAtAll->new( unknown => 1 ) },
      ':strict(params) complains even with no ADJUST block' );
   like( $@, qr/^Unrecognised parameters for NoParamsAtAll constructor: 'unknown' at /,
      'message from unrecognised param to constructor' );
}

{
   my $newarg_destroyed;
   my $buildargs_result_destroyed;
   package DestroyWatch {
      sub new { bless [ $_[1] ], $_[0] }
      sub DESTROY { ${ $_[0][0] }++ }
   }

   class RefcountTest {
      sub BUILDARGS {
         return DestroyWatch->new( \$buildargs_result_destroyed )
      }
   }

   RefcountTest->new( DestroyWatch->new( \$newarg_destroyed ) );

   is( $newarg_destroyed, 1, 'argument to ->new destroyed' );
   is( $buildargs_result_destroyed, 1, 'result of BUILDARGS destroyed' );
}

# Create a base class with HASH representation
{
   class NativelyHash :repr(HASH) {
      field $field = "value";
      method field { $field }
   }

   my $o = NativelyHash->new;
   is( reftype $o, "HASH", 'NativelyHash is natively a HASH reference' );
   is( $o->field, "value", 'native HASH objects still support fields' );
}

# Create a base class with keys representation
{
   class NativelyHashWithKeys :repr(keys) {
      field $s = "value";
      field @a = ( 12, 34 );
      field %h;
      method fields { $s, \@a, \%h }
   }

   my $o = NativelyHashWithKeys->new;
   is( reftype $o, "HASH", 'NativelyHashWithKeys is natively a HASH reference' );
   is( [ $o->fields ], [ "value", [ 12, 34 ], {} ],
      ':repr(keys) objects still support fields' );
   is( $o->{'NativelyHashWithKeys/$s'}, "value",
      ':repr(keys) object fields directly accessible' );
   is( $o,
      { 'NativelyHashWithKeys/$s' => "value",
        'NativelyHashWithKeys/@a' => [ 12, 34 ],
        'NativelyHashWithKeys/%h' => {},
      },
      ':repr(keys) object entirely' );
}

# Subclasses without BUILD shouldn't double-invoke superclass
{
   my $BUILD_invoked;
   class One {
      BUILD { $BUILD_invoked++ }
   }
   class Two {
      inherit One;
   }

   Two->new;
   is( $BUILD_invoked, 1, 'One::BUILD invoked only once for Two->new' );
}

done_testing;
