#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Syntax::Keyword::Match;

# `my` var inside expression works
{
   my $var = "outside";

   my $ok;
   match(my $var = 123 : ==) {
      case(123) {
         $ok++;
         is( $var, 123, '$var is topic inside case block' );
      }
   }
   ok( $ok, 'case block invoked' );
   is( $var, "outside", 'Topic var did not leak from match/case' );
}

done_testing;
