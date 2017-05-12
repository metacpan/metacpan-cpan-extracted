#!/usr/bin/perl -w
#
# Demonstrate how return status from parallelized code can be used,
# and how the degree of parallelization can be controlled.  We
# will save the return status of all of the parallelized jobs, and print
# it out.  We will also override the default maximum number of 5 parallel
# tasks, and only use 2.

use strict;
use Proc::ParallelLoop;

sub do_some_work($);
my @parms = ('a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k');

# Run the "do_some_work()" routine on each element of @parms in parallel.
my @status = pareach [ @parms ], sub {
                do_some_work(shift);
             }, {"Max_Workers"=>2};

# We may now check the exit status of our tests if we like.
print "The return statuses from the jobs were:\n  ";
for (my $i=0; $i<@parms; $i++) {
   print " " . $parms[$i] . ":" . $status[$i];
}
print "\n";

###############################################################################
# This is our work routine.  Running it in parallel speeds up our program.
sub do_some_work($) {

   print "Working with $_[0]...\n";
   sleep 2;  # Pretend we're busy doing something.

   # Let's see what happens if a fatal error occurs.
   if($_[0] eq "e") {
      die "   Testing what happens when die is invoked in the loop body.\n";
   }

   print "Finished using $_[0]\n";

   # Let's return a non-zero status for the "c" test.
   if($_[0] eq "c") { print "   Returning nonzero exit status 5\n" ; exit 5; }
}
###############################################################################
# EOF: example3.pl
