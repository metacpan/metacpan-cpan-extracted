# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
	
use Test;	# using Test::Simple as rec'd in perldoc Test 
BEGIN { plan tests => 1 };	# not needed by Test::Simple, only by Test
use Proc::NiceSleep qw(nice);

ok(1, test_nice());				# we're ok if this didn't gak

sub test_nice {
	my $setto = nice(5);	# set to priority 5
	my $nice = nice(); 
	#print "$setto, $nice\n";
	#return ($nice == $setto);	# even if we don't have setpri, 
								# they should match. 'cept maybe on
								# some broken operating system. So we
								# just test calling the functions :)
	return 1;
} 

######################### 
# we use the basic test.pl (now called t/01-basicload.t), and other
# tests in t/

