#!/usr/bin/perl

use v5.18;
use warnings;

use Test2::V0;

use Object::Pad 0.800 ':experimental(lexical_class)';

{
   my class Point {
      field $x :param :reader;
      field $y :param :reader;
   }

   my $p = Point->new( x => 20, y => 40 );
   ok( defined $p, 'Lexical class Point can ->new' );
   is( $p->x, 20, 'Lexical class instances have methods' );

   ok( !defined &Point::new, 'Point:: is not a package in the symbol table' );

   ok( $p->isa( Point ), '->isa method works with lexical name as bareword' );

   if( $^V ge v5.32 ) {
      eval <<'EOPERL' or die $@;
         use feature 'isa';
         ok( $p isa Point, 'isa operator works with lexical class' );
         1;
EOPERL
   }
}

{
   # A second lexical class of the same lexical name in its own scope should
   # be distinct
   my class Point {
      field $z :param :reader;
   }

   my $p = Point->new( z => 60 );
   is( $p->z, 60, 'Second lexical class of the same name in its own scope works' );
   ok( !$p->can( "x" ), 'Second lexical class is distinct from the first' );
}

done_testing;
