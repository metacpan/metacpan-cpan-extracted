#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Refcount;

use Object::Pad;

class Point {
   method BUILD { @$self = @_; }

   method where { sprintf "(%d,%d)", @$self }
}

{
   my $p = Point->new( 10, 20 );
   is_oneref( $p, '$p has refcount 1 initially' );

   is( $p->where, "(10,20)", '$p->where' );
   is_oneref( $p, '$p has refcount 1 after method' );
}

# anon methods
{
   class Point3 {
      method BUILD { @$self = @_; }

      our $clearer = method {
         @$self = ( 0 ) x 3;
      };
   }

   my $p = Point3->new( 1, 2, 3 );
   $p->$Point3::clearer();

   is_deeply( [ @$p ], [ 0, 0, 0 ],
      'anon method' );
}

done_testing;
