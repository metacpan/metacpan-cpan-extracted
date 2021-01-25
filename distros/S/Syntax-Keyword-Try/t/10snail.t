#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Syntax::Keyword::Try;

# try gets @_
{
   my @args;
   ( sub {
      try { @args = @_ }
      catch ($e) {}
   } )->( 1, 2, 3 );

   is_deeply( \@args, [ 1, 2, 3 ], 'try{} sees surrounding @_' );
}

# catch sees @_
{
   my @args;
   ( sub {
      try { die "oopsie" }
      catch ($e) { @args = @_ }
   } )->( 4, 5, 6 );

   is_deeply( \@args, [ 4, 5, 6 ], 'catch{} sees @_' );
}

done_testing;
