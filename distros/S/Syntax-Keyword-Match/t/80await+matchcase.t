#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

BEGIN {
   plan skip_all => "Future is not available"
      unless eval { require Future };
   plan skip_all => "Future::AsyncAwait >= 0.10 is not available"
      unless eval { require Future::AsyncAwait;
                    Future::AsyncAwait->VERSION( '0.10' ) };
   plan skip_all => "Syntax::Keyword::Match is not available"
      unless eval { require Syntax::Keyword::Match; };

   Future::AsyncAwait->import;
   Syntax::Keyword::Match->import;

   diag( "Future::AsyncAwait $Future::AsyncAwait::VERSION, " .
         "Syntax::Keyword::Match $Syntax::Keyword::Match::VERSION" );
}

# await in match/case
{
   async sub with_matchcase
   {
      my $f = shift;

      match( ref $f : eq ) {
         case( "Future" ) {
            await $f;
         }
         default {
            die "await case did not run";
         }
      }

      return "result";
   }

   my $f1 = Future->new;
   my $fret = with_matchcase( $f1 );

   $f1->done;
   is( scalar $fret->get, "result", '$fret for await in sswitch/case' );
}

done_testing;
