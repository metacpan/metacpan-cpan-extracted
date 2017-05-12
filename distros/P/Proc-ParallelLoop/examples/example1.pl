#!/usr/bin/perl -w
#
# Demonstrate how a typical foreach loop can be converted to a parallelized
# loop using pareach.

use strict;
use Proc::ParallelLoop;

sub do_some_work($);
my @parms = ('a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k');

# Do some work on each element of @parms.  This could have been written
# sequentially as:
#
#    foreach my $i (@parms) {
#       do_some_work($i);
#    }
#
# But instead, we will do it in parallel like this:

pareach [ @parms ], sub {
   my $i = shift;
   do_some_work($i);
};


###############################################################################
# This is our work routine.  Running it in parallel speeds up our program.
sub do_some_work($) {
   print "Working with $_[0]...\n";
   sleep 2;  # Pretend we're busy doing something.
   print "Finished using $_[0]\n";
}
###############################################################################
# EOF: example1.pl
