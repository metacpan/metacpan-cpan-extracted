#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

BEGIN {
   plan skip_all => "Future is not available"
      unless eval { require Future };
   plan skip_all => "Future::AsyncAwait >= 0.31_002 is not available"
      unless eval { require Future::AsyncAwait;
                    Future::AsyncAwait->VERSION( '0.31_002' ) };
   plan skip_all => "Syntax::Keyword::Dynamically >= 0.01 is not available"
      unless eval { require Syntax::Keyword::Dynamically;
                    Syntax::Keyword::Dynamically->VERSION( '0.01' ) };

   Future::AsyncAwait->import;
   Syntax::Keyword::Dynamically->import(qw( -async ));

   diag( "Future::AsyncAwait $Future::AsyncAwait::VERSION, " .
         "Syntax::Keyword::Dynamically $Syntax::Keyword::Dynamically::VERSION" );
}

{
   my $var = 1;
   async sub with_dynamically
   {
      my $f = shift;

      dynamically $var = 2;

      is( $var, 2, '$var is 2 before await' );
      await $f;
      is( $var, 2, '$var is 2 after await' );

      return "result";
   }

   my $f1 = Future->new;
   my $fret = with_dynamically( $f1 );

   is( $var, 1, '$var is 1 while suspended' );

   $f1->done;
   is( scalar $fret->get, "result", '$fret for dynamically in async sub' );
   is( $var, 1, '$var is 1 after finish' );
}

# multiple nested scopes
{
   my $var = 1;

   my @f;
   sub tick { push @f, my $f = Future->new; return $f }

   async sub with_dynamically_nested
   {
      dynamically $var = 2;

      {
         dynamically $var = 3;

         await tick();

         is( $var, 3, '$var is 3 in inner scope' );
      }

      is( $var, 2, '$var is 2 in outer scope' );

      await tick();

      is( $var, 2, '$var is still 2 in outer scope' );
   }

   my $fret = with_dynamically_nested();

   is( $var, 1, '$var is 1 while suspended' );

   while( @f ) {
      ( shift @f )->done;
      is( $var, 1, '$var is still 1' );
   }

   $fret->get;
   is( $var, 1, '$var is 1 after finish' );
}

# OP_HELEM_DYN is totally different in async mode
{
   my %hash = my %orig = (
      key    => "old",
      delkey => "gone",
   );
   async sub with_dynamically_helem
   {
      my $f = shift;

      dynamically $hash{key} = "new";
      dynamically $hash{newkey} = "added";

      dynamically $hash{delkey} = "begone!";
      delete $hash{delkey};

      await $f;

      is_deeply( \%hash, { key => "new", newkey => "added" },
         '%hash after await' );

      return "result";
   }

   my $f1 = Future->new;
   my $fret = with_dynamically_helem( $f1 );

   is_deeply( \%hash, \%orig, '%hash while suspended ');

   $f1->done;
   is( scalar $fret->get, "result", '$fret for dynamically helem in async sub' );
   is_deeply( \%hash, \%orig, '%hash after finish' );
}

# dynamically set variables in outer scopes during await
{
   my $var = 1;

   async sub outer
   {
      dynamically $var = 2;
      await inner();

      is( $var, 2, '$var is 2 after await in outer()' );
   }

   my $f1 = Future->new;

   async sub inner
   {
      is( $var, 2, '$var is 2 before await in inner()' );

      await $f1;

      is( $var, 2, '$var is 2 after await in inner()' );
   }

   my $fret = outer();

   is( $var, 1, '$var is 1 while suspended' );

   $f1->done;
   $fret->get;

   is( $var, 1, '$var is 1 after finish' );
}

# captured outer dynamic can be re-captured by later async sub
{
   my $var = 1;
   my %hash = ( key => 3 );

   my $f1 = Future->new;
   my $f2 = Future->new;

   my $fret = do {
      dynamically $var = 2;
      dynamically $hash{key} = 4;

      (async sub {
         await $f1;
         is( $var, 2, '$var is 2 before later await' );
         is( $hash{key}, 4, '$var is 4 before later await' );

         await +(async sub {
            await $f2;
            is( $var, 2, '$var is 2 inside inner async sub' );
            is( $hash{key}, 4, '$var is 4 inside inner async sub' );
         })->();
      })->();
   };

   is( $var, 1, '$var is 1 before $f1->done' );
   is( $hash{key}, 3, '$hash{key} is 3 before $f1->done' );

   $f1->done;
   is( $var, 1, '$var is 1 before $f2->done' );
   is( $hash{key}, 3, '$hash{key} is 3 before $f2->done' );

   $f2->done;
   is( $var, 1, '$var is 1 after $f2->done' );
   is( $hash{key}, 3, '$hash{key} is 3 after $f2->done' );

   $fret->get;
}

# destroy test
{
   my %state;

   package DestroyChecker {
      sub new {
         my $class = shift;
         my $self = bless [ @_ ], $class;
         $state{$self->[0]} = "LIVE";
         return $self;
      }

      sub DESTROY {
         my $self = shift;
         $state{$self->[0]} = "DEAD";
      }
   }

   dynamically my $var = DestroyChecker->new( "orig" );

   my $f1 = Future->new;
   my $fret = (async sub {
      dynamically $var = DestroyChecker->new( "new" );
      await $f1;
   })->();

   is_deeply( \%state, { orig => "LIVE", new => "LIVE" }, '%state initially' );

   $f1->done;
   $fret->get;

   is_deeply( \%state, { orig => "LIVE", new => "DEAD" }, '%state after done' );

   undef $var;

   is_deeply( \%state, { orig => "DEAD", new => "DEAD" }, '%state finally' );
}

done_testing;
