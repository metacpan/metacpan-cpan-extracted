#!/usr/bin/perl -wT

# this is a short example that illustrates use of Proc::NiceSleep

# Copyright (c) 2002-2018 Josh Rabinowitz, All rights reserved
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.

use strict; 

use Proc::NiceSleep qw(:all);

nice(5);	# lower our priority if possible 

min_run_time(0.001);	# how long to run without interruption

sleep_factor(1);	# sleepfactor = sleeptime / non-sleeptime, ie,
	# successive calls of maybesleep() will cause Proc::NiceSleep to
	# try to maintain (runtime * sleepfactor) = sleep time

for (my $i=0; $i < 5; $i++) {	# pretend to do five units of work
	do_some_work();	# pretend this actually did something for a second
	show_message("Did a little work...");
	my $slept = maybe_sleep(); 	# check to sleep.
	if ($slept) { 	# maybesleep() returns 0 if it didn't sleep
		show_message(sprintf("Slept %1.2f seconds.", $slept));
	}
} 
show_message("Done working!");

print "-------------------------------------------------\n";
print "-- Informational Data About Proc::NiceSleep: ----\n";
print Proc::NiceSleep::DumpText(); # show what went on inside 

exit(0);	# we're all finished here for now

########## UTILITY FUNCTIONS BELOW ################
# dosomework() just sit still for a bit, pretending to do work 
sub do_some_work { Proc::NiceSleep::sleep(0.985); }
#sub do_some_work { my $r = rand(7)/10; Proc::NiceSleep::sleep(.5 + $r); }

sub show_message { 
	my $message = shift; 
	printf("%-24s %s\n", $message, scalar(localtime(time())));
}


