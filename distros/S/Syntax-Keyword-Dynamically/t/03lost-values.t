#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Syntax::Keyword::Dynamically;

subtest "lost array element" => sub {
   my @array = ( "value" );

   {
      dynamically $array[0] = "new";
      # simply shift'ing the element leaves the underlying SV struct in the
      # AvARRAY, so we need to do something stronger
      @array = ();
   }
   pass( "shifting dynamically-assigned array element does not crash" );
};

subtest "lost hash entry" => sub {
   my %hash = ( key => "value" );

   {
      dynamically $hash{key} = "new";
      delete $hash{key};
   }
   pass( "deleting dynamically-assigned hash entry does not crash" );
};

done_testing;
