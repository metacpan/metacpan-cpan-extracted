# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#
#  This test program is dependant on a sample tcpdump file called "tcpdumplog"
#  existing in the same directory.
#
print "Using sample tcpdump output file \"tcpdumplog\" for testing\n\n";

use Test;
BEGIN { plan tests => 4 };
use Net::TcpDumpLog;

# 1. Ensure test file exists
$exists = -e "tcpdumplog";
print "1. Checking file exists... ";
ok($exists,1);

# 2. Test we can load the file as usual
print "2. Loading tcpdump file... ";
$log = Net::TcpDumpLog->new(32);	# force 32-bits to match this file
$log->read("tcpdumplog");
ok(1);

# 3. Test we loaded the correct number of frames
print "3. Checking we loaded the sample frames ok... ";
@Indexes = $log->indexes;
$num = @Indexes;
ok($num,185);

# 4. Test data in a frame is of correct length
print "4. Checking data in sample frame 0 is expected length... ";
$data = $log->data(0);
$length = length($data);
ok($length,62);

