#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Syntax::Keyword::Defer;

sub compile_fails_msg_line
{
   my ( $code, $message, $lineoff, $name ) = @_;
   my $tb = Test::Builder->new;

   my $ok = eval "#line 0 (compile_fails_msg_line)\nsub { $code }";
   my $e = "$@";

   if( $ok ) {
      $tb->ok(0, $name);
      diag( "Expected compile-time failure, did not happen" );
      return 0;
   }

   unless( $e =~ m/^$message at / ) {
      $tb->ok(0, $name);
      diag( "Expected compile-time failure matching $message\nGot failure $e" );
      return 0;
   }

   unless( $e =~ m/at \(compile_fails_msg_line\) line $lineoff\.?$/ ) {
      my ( $gotline ) = $e =~ m/ line (\d+)\.?$/;
      $tb->ok(0, $name);
      diag( "Expected compile-time failure from line $lineoff, got $gotline" );
      return 0;
   }

   $tb->ok(1, $name);
   return 1;
}

sub compiles_ok
{
   my ( $code, $name ) = @_;
   my $tb = Test::Builder->new;

   my $ok = eval "#line 0 (compiles_ok)\nsub { $code }";
   my $e = "$@";

   unless( $ok ) {
      $tb->ok(0, $name );
      diag( "Expected code to compile; failed with $e" );
      return 0;
   }

   $tb->ok(1, $name);
   return 1;
}

# return
{
   compile_fails_msg_line
      'while(1) {
         defer { return "retval" }
         last;
      }',
      q(Can't "return" out of a defer block), +1,
      'return out of defer {}';
}

# goto
{
   compile_fails_msg_line
      'while(1) {
         defer { goto HERE }
      }
      HERE: ;',
      q(Can't "goto" out of a defer block), +1,
      'goto out of defer {}';
}

# next/last/redo
{
   compile_fails_msg_line
      'while(1) {
         defer { last }
      }',
      q(Can't "last" out of a defer block), +1,
      'last out of defer {}';

   compile_fails_msg_line
      'LOOP: while(1) {
         defer { last LOOP }
      }',
      q(Can't "last" out of a defer block), +1,
      'last LABEL out of defer {}';

   compiles_ok
      'defer {
         foreach ( 1 .. 5 ) { last }
      }',
      'last within foreach';

   compiles_ok
      'defer {
         LOOP: foreach ( 1 .. 5 ) { next LOOP }
      }',
      'next LOOP within foreach LOOP';
}

done_testing;
