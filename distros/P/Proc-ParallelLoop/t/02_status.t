#!/usr/bin/perl -w
#
# Run a few parallel tests via pardo, and make sure we get the expected
# exit statuses back.

use strict;
use Proc::ParallelLoop;

# For our tests, we'll use a subroutine by that name.
sub test($);

# Here's a list of parameters to be "tested".
my @parms = ('a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k');

# Oh, don't mind me.
open STDERR, ">/dev/null";

# Run the "test()" routine on each element of @parms in parallel.
my @status = pareach \@parms, sub {
                test(shift);
             };

# We may now check the exit status of our tests if we like.
print "1..1\n";
if (join (' ', @status) eq '0 0 5 0 0 0 0 0 0 0 0') {
   print "ok 1\n";
} else {
   print "not ok 1\n";
}

# This is our test routine.  Running it in parallel speeds up our program.
sub test($) {

   # Pretend we are doing some work.
   sleep 1;

   # Let's see what happens if a fatal error occurs.
   if($_[0] eq "e") { die "   Testing worker process death.\n" }

   # Let's return a non-zero status for the "c" test.
   if($_[0] eq "c") { exit 5; }
}

# EOF: 02_status.t
