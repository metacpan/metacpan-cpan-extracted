#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Object::Pad::Operator::Of;
BEGIN { plan skip_all => "No PL_infix_plugin" unless XS::Parse::Infix::HAVE_PL_INFIX_PLUGIN; }

use Object::Pad;

class TestClass1 {
   field $f :param;

   method m ($other) {
      return "$f <=> " . $f of $other;
   }
}

{
   my $x = TestClass1->new( f => "first" );
   my $y = TestClass1->new( f => "second" );

   is( $x->m( $y ), "first <=> second",
      'm method can use of operator' );
}

class TestClass2 {
   field $f :param :reader;

   use overload '<=>' => method ( $other, $ ) {
      return $f <=> $f of $other;
   };
}

{
   my @objs = map { TestClass2->new( f => $_ ) } 10, 30, 20;
   is( [ map { $_->f } sort { $a <=> $b } @objs ],
       [ 10, 20, 30 ],
       'overloaded <=> operator method can use of operator' );
}

done_testing;
