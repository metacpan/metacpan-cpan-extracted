#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Object::Pad;

class Point {
   sub new { my $class = shift; return bless [ @_ ], $class }

   method where { sprintf "(%d,%d)", @$self }
}

{
   my $p = Point->new( 10, 20 );
   is( $p->where, "(10,20)", '$p->where' );
}

done_testing;
