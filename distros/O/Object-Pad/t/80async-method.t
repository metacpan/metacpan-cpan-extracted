#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;
use Test::Refcount;

BEGIN {
   plan skip_all => "Future is not available"
      unless eval { require Future };
   plan skip_all => "Future::AsyncAwait >= 0.45 is not available"
      unless eval { require Future::AsyncAwait;
                    Future::AsyncAwait->VERSION( '0.45' ) };
   plan skip_all => "Object::Pad >= 0.32 is not available"
      unless eval { require Object::Pad;
                    Object::Pad->VERSION( '0.32' ) };

   Future::AsyncAwait->import;
   Object::Pad->import;

   diag( "Future::AsyncAwait $Future::AsyncAwait::VERSION, " .
         "Object::Pad $Object::Pad::VERSION" );
}

# async method
{
   class Thunker {
      has $_times_thunked = 0;

      method count { $_times_thunked }

      async method thunk {
         my ( $f ) = @_;
         await $f;
         $_times_thunked++;
         return "result";
      }
   }

   my $thunker = Thunker->new;
   is_oneref( $thunker, 'after ->new' );

   my $f1 = Future->new;
   my $fret = $thunker->thunk( $f1 );
   is_refcount( $thunker, 3, 'during async sub' );
      # +1 because $self, +1 because of @(Object::Pad/slots) pseudolexical

   is( $thunker->count, 0, 'count is 0 before $f1->done' );

   $f1->done;

   is_oneref( $thunker, 'after ->done' );

   is( $thunker->count, 1, 'count is 1 after $f1->done' );
   is( $fret->get, "result", '$fret for await in async method' );
}

# RT133564
{
   # Hard to test this one but running the test itself shouldn't produce any
   # warnings of "Attempt to free unreferenced scalar ..."
   my $thunker = Thunker->new;
   eval {
      my $f = $thunker->thunk( Future->new );
      die "Oopsie\n";
   };
   ok( 1, "No segfault for RT133564 test" );
}

# RT137649
{
   my $waitf;

   role Role { async method m { await $waitf = Future->new } }
   class Class implements Role {}

   my $obj = Class->new;

   my $f1 = $obj->m;
   $waitf->done( "first" );
   is( await $f1, "first", 'First call OK' );

   my $f2 = $obj->m;
   $waitf->done( "second" );
   is( await $f2, "second", 'Second call OK' );
}

done_testing;
