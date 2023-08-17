#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Syntax::Keyword::Try;

# try success
{
   my $s;
   try {
      $s = 1;
   }
   catch ($e) {
      $s = 2;
   }

   is( $s, 1, 'sucessful try{} runs' );
}

# try catches
{
   my $s;
   ok( eval {
      try {
         die "oopsie";
      }
      catch ($e) { }

      $s = 3;
      "ok";
   }, 'try { die } is not fatal' );

   is( $s, 3, 'code after try{} runs' );
}

# exceptions that are false
{
   my $caught;
   try {
      die FALSE->new;
   }
   catch ($e) {
      $caught++;
   }

   ok( $caught, 'catch{} sees a false exception' );

   {
      package FALSE;
      use overload 'bool' => sub { 0 };
      sub new { bless [], shift }
   }
}

# catch sees exception
{
   my $caught;
   try {
      die "oopsie";
   }
   catch ($e) {
      $caught = $e;
   }

   like( $caught, qr/^oopsie at /, 'catch{} sees $@' );
}

# catch block executes
{
   my $s;
   try {
      die "oopsie";
   }
   catch ($e) {
      $s = 4;
   }

   is( $s, 4, 'catch{} of failed try{} runs' );
}

# catch can rethrow
{
   my $caught;
   ok( !eval {
      try { die "oopsie"; }
      catch ($e) { $caught = $e; die $e }
   }, 'die in catch{} is fatal' );
   my $e = $@;

   like( $e, qr/^oopsie at /, 'exception is thrown' );
   like( $caught, qr/^oopsie at /, 'exception was seen by catch{}' );
}

# catch without VAR
{
   try {
      die "caught\n";
   }
   catch {
      my $e = $@;
      is( $e, "caught\n", 'exception visible in $@' );
   }
}

# catch lexical does not retain
{
   my $destroyed;
   sub Canary::DESTROY { $destroyed++ }

   try {
      die bless [], "Canary";
   }
   catch ($e) {
      # don't touch $e
   }

   ok( $destroyed, 'catch ($var) does not retain value' );
}

{
   no Syntax::Keyword::Try;

   sub try { return "normal function" }

   is( try, "normal function", 'try() parses as a normal function call' );
}

done_testing;
