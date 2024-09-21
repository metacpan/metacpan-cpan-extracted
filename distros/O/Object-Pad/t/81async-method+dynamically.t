#!/usr/bin/perl

use v5.18;
use warnings;

use Test2::V0;

BEGIN {
   plan skip_all => "Future is not available"
      unless eval { require Future };
   plan skip_all => "Future::AsyncAwait >= 0.40 is not available"
      unless eval { require Future::AsyncAwait;
                    Future::AsyncAwait->VERSION( '0.40' ) };
   plan skip_all => "Object::Pad >= 0.800 is not available"
      unless eval { require Object::Pad;
                    Object::Pad->VERSION( '0.800' ) };
   plan skip_all => "Syntax::Keyword::Dynamically >= 0.04 is not available"
      unless eval { require Syntax::Keyword::Dynamically;
                    Syntax::Keyword::Dynamically->VERSION( '0.04' ) };

   Future::AsyncAwait->import;
   Object::Pad->import;
   Syntax::Keyword::Dynamically->import;

   diag( "Future::AsyncAwait $Future::AsyncAwait::VERSION, " .
         "Object::Pad $Object::Pad::VERSION, " .
         "Syntax::Keyword::Dynamically $Syntax::Keyword::Dynamically::VERSION" );
}

# dynamically inside an async method
{
   my $after_level;

   class Logger {
      field $_level = 1;

      method level { $_level }

      async method verbosely {
         my ( $code ) = @_;
         dynamically $_level = $_level + 1;
         await $code->();
         $after_level = $_level;
      }
   }

   my $logger = Logger->new;

   is( $logger->level, 1, '$logger->level initially' );

   my $during_level;
   my $f1 = Future->new;
   my $fret = $logger->verbosely(async sub {
      $during_level = $logger->level;
      await $f1;
   });

   is( $logger->level, 1, '$logger->level while verbosely suspended' );
   is( $during_level, 2, '$during_level' );

   $f1->done;

   is( $after_level, 2, '$after_level' );
   is( $logger->level, 1, '$logger->level finally' );
}

done_testing;
