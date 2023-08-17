#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Syntax::Keyword::Defer;

{
   my $sub = sub {
      defer { die "Oopsie\n"; }
      return "retval";
   };

   my $e = defined eval { $sub->(); 1 } ? undef : $@;

   is($e, "Oopsie\n", 'defer block can throw exception');
}

SKIP: {
   skip "Double exceptions break eval {} on older perls", 1 if $] < 5.020;

   my $sub = sub {
      defer { die "Subsequent oopsie\n"; }
      die "Main oopsie\n";
   };

   my $warnings;
   my $e = do {
      local $SIG{__WARN__} = sub { $warnings .= join "", @_ };
      defined eval { $sub->(); 1 } ? undef : $@;
   };

   like($e, qr/^Main oopsie\n/, 'Exception thrown during exceptional unwind does not overwrite');
   like($warnings, qr/\(in cleanup\) Subsequent oopsie\n/, 'Exception thrown within exceptional unwind is printed as warning');
}

done_testing;
