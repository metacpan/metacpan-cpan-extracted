# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl WMIClient.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 1;
use Net::WMIClient qw(wmiclient);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# Test output with a bad hostname:
my @params = ("//bogus", "select * from Win32_ComputerSystem");
my ($rc, $output) = wmiclient(@params);
ok($output eq "NTSTATUS: NT_STATUS_IO_TIMEOUT - NT_STATUS_IO_TIMEOUT\n", "Bogus network test");
