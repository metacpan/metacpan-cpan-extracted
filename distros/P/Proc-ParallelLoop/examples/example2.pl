#!/usr/bin/perl -w
#
# Demonstrate how a typical for loop can be converted to a parallelized
# loop using pardo.


use strict;
use Proc::ParallelLoop;

sub do_some_work($);
my @parms = ('a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k');

# Do some work on each element of @parms.  This could have been written
# sequentially as:
#
#    for (my $i=0; $i<@parms; $i++) {
#       do_some_work($parms[$i]);
#    }
#
# But instead, we will do it in parallel like this:

{ my $i=0; pardo sub{$i<@parms}, sub{$i++}, sub {
   do_some_work($parms[$i]);
};}

print "The loop has completed.\n";

###############################################################################
# This is our work routine.  Running it in parallel speeds up our program.
sub do_some_work($) {
   print "Working with $_[0]...\n";
   sleep 2;  # Pretend we're busy doing something.
   print "Finished using $_[0]\n";
}
###############################################################################
# EOF: example2.pl
