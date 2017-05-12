# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Net-DNS_A.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 7;
BEGIN { use_ok('ExtUtils::testlib') };
BEGIN { use_ok('Net::DNS_A') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my @output = Net::DNS_A::retrieve();
ok(0 == $output[0], "Please call lookup()");

ok(Net::DNS_A::lookup("google.com"), 'lookup("google.com")');
ok(Net::DNS_A::lookup("google.com"), 'Please call retrieve()');
sleep(1);
@output = Net::DNS_A::retrieve();
ok($output[0], "retrieve() :: $output[1] :: $output[2])");

@output = Net::DNS_A::retrieve();
ok(0 == $output[0], "Please call lookup()");
