#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use String::Tagged;

{
   my $str = String::Tagged->join( ", ",
      String::Tagged->new_tagged( "one", val => 1 ),
      String::Tagged->new_tagged( "two", val => 2 ),
      String::Tagged->new_tagged( "three", val => 3 ),
   );

   isa_ok( $str, [ "String::Tagged" ], 'String::Tagged->join returns String::Tagged' );
   is( "$str", "one, two, three", '->join yielded correct text' );

   is( $str->get_tag_at( 5, "val" ), 2, '->join preserves inner tags' );
}

done_testing;
