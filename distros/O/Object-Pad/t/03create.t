#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Scalar::Util qw( reftype );

use Object::Pad;

class Point {
   has $x = 0;
   has $y = 0;

   method BUILD {
      ( $x, $y ) = @_;
   }

   method where { sprintf "(%d,%d)", $x, $y }
}

{
   my $p = Point->new( 10, 20 );
   is( $p->where, "(10,20)", '$p->where' );
}

my @buildargs;
my @buildall;

class WithBuildargs {
   sub BUILDARGS {
      @buildargs = @_;
      return ( 4, 5, 6 );
   }

   method BUILD {
      @buildall = @_;
   }
}

{
   WithBuildargs->new( 1, 2, 3 );

   is_deeply( \@buildargs, [qw( WithBuildargs 1 2 3 )], '@_ to BUILDARGS' );
   is_deeply( \@buildall,  [qw( 4 5 6 )],               '@_ to BUILD' );
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

done_testing;
