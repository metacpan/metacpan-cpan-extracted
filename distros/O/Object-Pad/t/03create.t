#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Scalar::Util qw( reftype );

use Object::Pad;

class Point {
   has $x = 0;
   has $y = 0;

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

   is_deeply( \@buildargs, [qw( WithBuildargs 1 2 3 )], '@_ to BUILDARGS' );
   is_deeply( \@build,     [qw( 4 5 6 )],               '@_ to BUILD' );
}

{
   my @called;

   class WithAdjust {
      BUILD {
         push @called, "BUILD";
      }

      ADJUST {
         push @called, "ADJUST";
      }
   }

   WithAdjust->new;
   is_deeply( \@called, [qw( BUILD ADJUST )], 'ADJUST invoked after BUILD' );
}

{
   my @called;
   my $paramsref;

   class WithAdjustParams {
      ADJUST {
         push @called, "ADJUST";
      }

      ADJUSTPARAMS {
         my ( $href ) = @_;
         push @called, "ADJUSTPARAMS";
         $paramsref = $href;
      }

      ADJUST {
         push @called, "ADJUST";
         Test::More::ok( !scalar @_, 'ADJUST block received no arguments' );
      }
   }

   WithAdjustParams->new( key => "val" );
   is_deeply( \@called, [qw( ADJUST ADJUSTPARAMS ADJUST )], 'ADJUST and ADJUSTPARAMS invoked together' );
   is_deeply( $paramsref, { key => "val" }, 'ADJUSTPARAMS received HASHref' );
}

{
   my $paramvalue;

   class StrictlyWithParams :strict(params) {
      ADJUSTPARAMS {
         my ($href) = @_;
         $paramvalue = delete $href->{param};
      }
   }

   StrictlyWithParams->new( param => "thevalue" );
   is( $paramvalue, "thevalue", 'ADJUSTPARAMS captured the value' );

   ok( !defined eval { StrictlyWithParams->new( unknown => "name" ) },
      ':strict(params) complains about unrecognised param' );
   like( $@, qr/^Unrecognised parameters for StrictlyWithParams constructor: unknown at /,
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
      has $slot = "value";
      method slot { $slot }
   }

   my $o = NativelyHash->new;
   is( reftype $o, "HASH", 'NativelyHash is natively a HASH reference' );
   is( $o->slot, "value", 'native HASH objects still support slots' );
}

# Subclasses without BUILD shouldn't double-invoke superclass
{
   my $BUILD_invoked;
   class One {
      BUILD { $BUILD_invoked++ }
   }
   class Two isa One {}

   Two->new;
   is( $BUILD_invoked, 1, 'One::BUILD invoked only once for Two->new' );
}

done_testing;
