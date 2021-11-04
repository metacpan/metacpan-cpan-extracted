#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Syntax::Keyword::Try;

# return from try
{
   my $after;
   ( sub {
      try { return }
      catch ($e) {}
      $after++;
   } )->();
   ok( !$after, 'code after try{return} in void context is not invoked' );
}

# return SCALAR from try
{
   is(
      scalar ( sub {
         try { return "result" }
         catch ($e) {}
         return "nope";
      } )->(),
      "result",
      'return SCALAR in try yields correct value'
   );
}

# return LIST from try
{
   is_deeply(
      [ sub {
         try { return qw( A B C ) } catch ($e) {}
      }->() ],
      [qw( A B C )],
      'return LIST in try yields correct values'
   );
}

# return from two nested try{}s
{
   my $after;

   is(
      ( sub {
         try {
            try { return "result" }
            catch ($e) {}
         }
         catch ($e) {}
         $after++;
         return "nope";
      } )->(),
      "result",
      'return in try{try{}} leaves containing function'
   );
   ok( !$after, 'code after try{try{return}} is not invoked' );
}

# return inside eval{} inside try{}
{
   is(
      ( sub {
         my $two;
         try {
            my $one = eval { return 1 };
            $two = $one + 1;
         }
         catch ($e) {}
         return $two;
      } )->(),
      2,
      'return in eval{} inside try{} behaves as expected'
   );
}

# return inside try{} inside eval{}
{
   is(
      ( sub {
         my $ret = eval {
            try { return "part"; }
            catch ($e) {}
         };
         return "($ret)";
      } )->(),
      "(part)",
      'return in try{} inside eval{}'
   );
}

# return from catch
{
   is(
      ( sub {
         try { die "oopsie" }
         catch ($e) { return "result" }
         return "nope";
      } )->(),
      "result",
      'return in catch leaves containing function'
   );
}

done_testing;
