# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################
# this tests that Proc::NiceSleep::reset() works as expected.
#########################

# change 'tests => 1' to 'tests => last_test_to_print'; 
use Test::More tests => 1; 

use Proc::NiceSleep qw(maybe_sleep min_run_time sleep_factor);	

Proc::NiceSleep::sleep_factor( 1 );

test_reset(); # If we made it this far, we're ok.  

# on win32 with Time::HiRes, we found that sleep() sometime
# seemed to sleep very briefly. hence the repeats of sleep() and
# maybesleep()
sub test_reset {
	print "Running about 1 seconds...\n";	# we try to do this fast
	min_run_time(0);
	sleep_factor(1.1);

	my $t1 = Proc::NiceSleep::time();
	while(Proc::NiceSleep::time() - $t1 <= 1) {
		Proc::NiceSleep::sleep(.5);	
		# successive sleeps for at least 1 apparent second
	}
	Proc::NiceSleep::reset_all();
	my $href = Proc::NiceSleep::Dump(); 	# returns hashref of info
	cmp_ok( $href->{TOTAL_SLEEP_TIME}, '==', 0, "total runtime reset");

}

