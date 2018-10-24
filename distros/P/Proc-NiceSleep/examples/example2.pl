#!/usr/bin/perl -wT
# this is a short example that illustrates use of Proc::NiceSleep

# Copyright (c) 2002-2018 Josh Rabinowitz, All rights reserved
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.

use strict; 

use Proc::NiceSleep qw(:all);
eval ('require Sys::CpuLoad');
if($@) { die "Sys::CpuLoad required for Proc::NiceSleep::max_load() to work"; }

print "Using Proc::NiceSleep v$Proc::NiceSleep::VERSION\n";

# Proc::NiceSleep does not _require_ Sys::CpuLoad, but 
# the max_load() option will have no effect if it is not found.
# So we go ahead and use it for illustrative purposes in this script.  

nice(5);	# lower our priority if possible
print "-----------------------------------------------\n";
print "-- Informational Data About Proc::NiceSleep: --\n";
print Proc::NiceSleep::DumpText(); # show what went on inside 
test_load();
print "-----------------------------------------------\n";
print "-- Informational Data About Proc::NiceSleep: --\n";
print Proc::NiceSleep::DumpText(); # show what went on inside 
exit(0);	# we're all finished here for now

## now, test load feature... this might not work
# if the system is being used by other processes, but
# you can get the idea here...  
sub test_load {
	my ($load1, $load5, $load15) = Sys::CpuLoad::load();
	$load1 ||= 0;
	my $new_max_load = sprintf("%.2f", $load1 + 0.01);
	show_message("Setting max_load to $new_max_load");
	max_load($new_max_load);
	sleep_factor(0);
	my $t1 = Proc::NiceSleep::time();
	my $lastshowtime = 0;
	while(Proc::NiceSleep::time() - $t1 < 10) {	# for up to 10 seconds...	
		my $t2 = Proc::NiceSleep::time();
		my ($load, $load5, $load15) = Sys::CpuLoad::load();
		show_message("Working...  load is " . sprintf("%.2f",  $load) . "." );
		while(Proc::NiceSleep::time() - $t2 < 1) {	# for one second...
			for (my $i=0; $i < 1000; $i++) { my $b = $i + $i; }	# work!
		}
		($load) = Sys::CpuLoad::load();
		#if (my $l = maybe_sleep()) {
		{ 
			my $l = maybe_sleep();
			show_message("Slept " . sprintf("%1.1f", $l) . 
				"s, load is " . sprintf("%.2f",  $load) . "." );
		}
	} 
}

########## UTILITY FUNCTIONS BELOW ################
sub show_message { 
	my $message = shift; 
	printf("%-30s %s\n", $message, scalar(localtime(time())));
}


