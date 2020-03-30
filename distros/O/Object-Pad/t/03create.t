#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

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

   method BUILDALL {
      @buildall = @_;
   }
}

{
   WithBuildargs->new( 1, 2, 3 );

   is_deeply( \@buildargs, [qw( WithBuildargs 1 2 3 )], '@_ to BUILDARGS' );
   is_deeply( \@buildall,  [qw( 4 5 6 )],               '@_ to BUILDALL' );
}

done_testing;
