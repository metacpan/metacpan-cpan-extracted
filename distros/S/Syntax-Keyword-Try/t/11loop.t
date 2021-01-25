#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Syntax::Keyword::Try;

# try can apply loop controls
{
   my $count = 0;
   LOOP: {
      try {
         $count++;
         redo LOOP if $count < 2;
      }
      catch ($e) { }
   }

   is( $count, 2, 'try{redo} works' );

   $count = 0;
   my $after = 0;

   LOOP2: {
      try {
         last LOOP2;
         $after++; # just to put a statement after 'last'
      }
      catch ($e) { }
      $count++;
   }

   is( $count, 0, 'try{last} works' );
}

# catch can apply loop controls
{
   my $count = 0;
   LOOP: {
      try {
         die "oopsie";
      }
      catch ($e) {
         $count++;
         redo LOOP if $count < 2;
      }
   }

   is( $count, 2, 'catch{redo} works' );

   $count = 0;

   LOOP2: {
      try {
         die "oopsie";
      }
      catch ($e) {
         last LOOP2;
      }
      $count++;
   }

   is( $count, 0, 'catch{last} works' );
}

done_testing;
