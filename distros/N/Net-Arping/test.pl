# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 1 };
use Net::Arping;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

$a=Net::Arping->new();
print "Arpinging host 194.93.190.123\n";

$b=$a->arping("194.93.190.123");

print "Returned result is $b \n It means that:\n";

if($b eq "0") {
	print "Host is dead\n";
} else {
	print "Host is alive. Reply was from mac address $b\n";
}
ok(1);

