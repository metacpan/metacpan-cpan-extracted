#!/usr/bin/perl

use v5.18;
use warnings;

use Test2::V0;

use Object::Pad 0.800;

use constant HAVE_SUBNAME => $^V ge v5.22;
use if HAVE_SUBNAME, 'Sub::Util' => qw( subname );

class Point :lexical_new
{
   sub create
   {
      shift;
      my ( $x, $y ) = @_;
      return new( __PACKAGE__, x => $x, y => $y );
   }

   sub get_constructor { return \&new; }

   field $x :param :reader;
   field $y :param :reader;
}

{
   my $p = Point->create( 10, 20 );
   ok( defined $p, 'Lexically constructed class Point can ->new' );
   is( $p->x, 10, 'Lexically constructed class instances have methods' );

   ok( !defined &Point::new, '&Point::new is not in the symbol table' );

   ok( !defined &new, 'my sub &new did not leak into lexical scope' );

   if( HAVE_SUBNAME ) {
      is( subname( Point->get_constructor ), "Point::new", 'subname of lexical constructor' );
   }
}

done_testing;
