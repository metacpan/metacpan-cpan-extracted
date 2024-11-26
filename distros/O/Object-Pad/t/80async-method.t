#!/usr/bin/perl

use v5.18;
use warnings;

use Test2::V0 0.000148; # is_refcount

use Test2::Require::Module 'Future' => '0.49';
use Test2::Require::Module 'Future::AsyncAwait' => '0.45';
use Test2::Require::Module 'Object::Pad' => '0.800';

BEGIN {
   # If Future::XS is installed, then check it's at least 0.08; earlier
   # versions will crash
   if( eval { require Future::XS } ) {
      plan skip_all => "Future::XS is installed but it is older than 0.08"
         unless eval { Future::AsyncAwait->VERSION( '0.08' ); };
   }
}

use Future::AsyncAwait;
use Object::Pad;

# async method
{
   class Thunker {
      field $_times_thunked = 0;

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
   class Class { apply Role; }

   my $obj = Class->new;

   my $f1 = $obj->m;
   $waitf->done( "first" );
   is( await $f1, "first", 'First call OK' );

   my $f2 = $obj->m;
   $waitf->done( "second" );
   is( await $f2, "second", 'Second call OK' );
}

# RT151046
if( $^V ge v5.26 ) {
   eval <<'EOPERL' or die $@;
role RT151046 { async method foo(); }
EOPERL
   pass( 'Required method declarations may be declared as async' );
}

done_testing;
