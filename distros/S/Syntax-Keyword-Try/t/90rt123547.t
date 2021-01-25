#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

# RT123547 observes that if S:K:T is loaded late after multiple threads
#   are actually started, it will crash

BEGIN {
   eval { require threads; threads->import; 1 } or
      plan skip_all => "threads are not supported";
}

# Start two threads doing the same thing concurrently and hope we get
#   to the end
my @threads = map {
   threads->create( sub {
      my $x;

      # We have to late-load the module and then demonstrate that it works
      # Because of late loading we couldn't have written normal code here, so
      #   we'll string-eval it
      eval <<'EOPERL'
      use Syntax::Keyword::Try;

      try {
         $x = "a";
         die "oops";
      }
      catch ($e) {
         $x .= "b";
      }
      finally {
         $x .= "c";
      }
      1;
EOPERL
         or die "Failed - $@";
      return $x;
   } );
} 1 .. 2;

is( $_->join, "abc", 'try/catch/finally correct result' ) for @threads;

pass "Did not crash";

done_testing;
