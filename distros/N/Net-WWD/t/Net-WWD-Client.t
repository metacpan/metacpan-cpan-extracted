# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-WWD-Client.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

#use Test::More tests => 2;
BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

# Test 2:

use Net::WWD::Functions;
use Net::WWD::Client;
$wwd = new Net::WWD::Client;
if($wwd->get("idserver.org","id") eq "IDSERVER.Org") {
	print "ok 2\n";
} else {
	print "not ok 2\n";
}
my $name = time;
$wwd->auth("perltest","perltesting");
# PLEASE do not use this account. Register for your free account at http://idserver.org/wwd/create_account.wwd

# TEST setting / creating a new object
$wwd->set("idserver.org",$name,"TEST","","","","0");
$boolOkay = "0";
if($wwd->get("idserver.org","perltest/${name}") eq "TEST") {
	print "ok 3\n";
	$boolOkay = "1";
} else {
	print "not ok 3\n";
	$boolOkay = "0";
}

$wwd->delete("idserver.org","perltest/${name}");
if(($wwd->get("idserver.org","perltest/${name}") eq "UNKNOWN OBJECT")&&($boolOkay eq "1")) {
	print "ok 4\n";
} else {
	print "not ok 4\n";
}

