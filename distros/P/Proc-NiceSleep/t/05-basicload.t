# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
	
use Test;

# we were going to use Test::Simple as rec'd in perldoc Test, but 
# Test::Simple isn't included by default even as of perl 5.6.1

BEGIN { plan tests => 1 };	# not needed by Test::Simple, only by Test

use Proc::NiceSleep qw(maybe_sleep min_run_time min_sleep_time max_load sleep_factor);	

Proc::NiceSleep::min_run_time(.0001);	
#Proc::NiceSleep::min_sleep_time(.0001);	

# init it; this should check for Sys::CpuLoad

if ($Proc::NiceSleep::_havesyscpuload) {
	ok(test_load()); # If we made it this far, we're ok.  
} else {
	skip(1, 1, 1); # what is up with params to skip() ?
}

# we can't really test this in all circumstatnce, other things could be 
# using the  CPU to cause our 'load' data to be influenced very little by
# us. We test that everything loads ok and works, and we test that we can
# drive the load up a little (maybe we cant) and sleep as a result
sub test_load {
	# this better work, we already tested!!
	my $load1 = Sys::CpuLoad::load();
	max_load(.01);
	my $t1 = Proc::NiceSleep::time();
	while(Proc::NiceSleep::time() - $t1 < 5) {	# for up to 5 seconds...
		for (my $i=0; $i < 10000; $i++) { my $b = $i + $i; }	# work!
		my $load2 = Sys::CpuLoad::load();
		return 1 if ( ($load2 > $load1 && maybe_sleep()) || maybe_sleep());	
		# goody! raised & slept
	} 
	1; # hey, just cause we couldn't raise the load doesn't mean we failed
}

