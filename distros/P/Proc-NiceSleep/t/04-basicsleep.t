# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
	
use Test;

# we were going to use Test::Simple as rec'd in perldoc Test, but 
# Test::Simple isn't included by default even as of perl 5.6.1

BEGIN { plan tests => 1 };	# not needed by Test::Simple, only by Test

use Proc::NiceSleep qw(maybe_sleep min_run_time sleep_factor);	

ok(1, test_sleep()); # If we made it this far, we're ok.  

# on win32 with Time::HiRes, we found that sleep() sometime
# seemed to sleep very briefly. hence the repeats of sleep() and
# maybesleep()
sub test_sleep {
	print "Sleeping about 1 seconds...\n";	# we try to do this fast
	min_run_time(0);
	sleep_factor(1.1);

	my $t1 = Proc::NiceSleep::time();
	while(Proc::NiceSleep::time() - $t1 <= 1) {
		Proc::NiceSleep::sleep(.5);	
		# successive sleeps for at least 1 apparent second
	}

	maybe_sleep();	# in case one of these returns too fast,
	maybe_sleep();	# we call it extra times...
	maybe_sleep();	# they should have no effect
	maybe_sleep();	# they should have no effect
	maybe_sleep();	# they should have no effect :)

	my $t2 = Proc::NiceSleep::time();
	my $t = $t2 - $t1;
	return ($t > 2.0);	# maybe_sleep()s should have slept ~1.5 seconds
}

