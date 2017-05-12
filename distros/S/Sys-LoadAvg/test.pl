# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 1 };
use Sys::LoadAvg;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.


#print join(" ", Sys::LoadAvg::loadavg()), $/; 
#my @load = Sys::LoadAvg::loadavg(); 
#print $load[LOADAVG_1MIN], $/;
#print $load[LOADAVG_5MIN], $/;
#print $load[LOADAVG_15MIN], $/;
