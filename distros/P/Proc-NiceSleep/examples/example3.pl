#!/usr/bin/perl -wT
use strict; 

# a short example that illustrates use of Proc::NiceSleep::load_function()

# Copyright (c) 2002-2018 Josh Rabinowitz, All rights reserved
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.


my $load_function_call_count = 0;
sub my_load_function { 
	$load_function_call_count++; 
	my $fakeload = sprintf("%0.2f", rand(3));
	# pretend the load changes randomly in the range 0 to 3
	return ($fakeload, $fakeload, $fakeload);		# pretend 1, 5, 15 minute loads
}	

use Proc::NiceSleep qw(:all);
eval ('require Sys::CpuLoad');
if($@) { die "Sys::CpuLoad required for Proc::NiceSleep::max_load() to work"; }

print "Using Proc::NiceSleep v$Proc::NiceSleep::VERSION\n";

# Proc::NiceSleep does not _require_ Sys::CpuLoad, but 
# the max_load() option will have no effect if it is not found.
# So we go ahead and use it for illustrative purposes in this script.  

nice(5);	# lower our priority if possible 

load_function( \&my_load_function );	# set up the load_function callback
max_load(2);	# set the max load to 2, for kicks ('load' will be 0-3)

maybe_sleep();	# now, call it again!
maybe_sleep();	# note that the load is only checked about once each second,
				# so $load_function_call_count could be one, not two.

print "my_load_function() was called $load_function_call_count times!\n";

print "-----------------------------------------------\n";
print "-- Informational Data About Proc::NiceSleep: --\n";
print Proc::NiceSleep::DumpText(); # show what went on inside 
exit(0);	# we're all finished here for now


