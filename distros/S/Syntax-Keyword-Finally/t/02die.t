#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Syntax::Keyword::Finally;

{
   my $sub = sub {
      FINALLY { die "Oopsie\n"; }
      return "retval";
   };

   my $e = defined eval { $sub->(); 1 } ? undef : $@;

   is($e, "Oopsie\n", 'FINALLY block can throw exception');
}

SKIP: {
   skip "Double exceptions break eval {} on older perls", 1 if $] < 5.020;

   my $sub = sub {
      FINALLY { die "Oopsie 1\n"; }
      die "Oopsie 2\n";
   };

   my $e = defined eval { $sub->(); 1 } ? undef : $@;

   # TODO: Currently the first exception gets lost without even a warning
   #   We should consider what the behaviour ought to be here
   # This test is happy for either exception to be seen, does not care which
   like($e, qr/^Oopsie \d\n/, 'FINALLY block can throw exception during exception unwind');
}

done_testing;
