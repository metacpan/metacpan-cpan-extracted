
# Copyright (c) 2006-2010 James Raftery <james@now.ie>. All rights reserved.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..7\n"; }
END {print "not ok 1\n" unless $loaded;}
use Net::Pcap::Reassemble;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

#
# Test 2: Attach to a dump file
#
use vars qw($i);
my $err;

my $pcap_t = Net::Pcap::open_offline("t/ipv4-frag.pcap", \$err);
if (!defined($pcap_t)) {
	print "not ok 2\n";
	exit 1;
}
print "ok 2\n";

#
# Test 3: Read from an IPv4 dump file. It contains one whole datagram
#         and one datagram in two fragments. The anonymous callback
#         should therefore be called only twice (for two whole
#         datagrams) instead of three times (for each captured
#         packet).
#
$i = 0;
Net::Pcap::Reassemble::loop($pcap_t, -1, sub {$i++}, "");
Net::Pcap::close($pcap_t);
$pcap_t = undef;
Net::Pcap::Reassemble::flush();

if ($i == 2) {
	print "ok 3\n";
} else {
	print "not ok 3\n";
}

#
# Test 4: Detach and attach to a different dump file.
#
$pcap_t = Net::Pcap::open_offline("t/ipv6-frag.pcap", \$err);
if (!defined($pcap_t)) {
	print "not ok 4\n";
	exit 1;
}
print "ok 4\n";

#
# Test 5: Read from an IPv6 dump file. It contains one whole datagram
#         and one datagram in three fragments. The callback should
#         therefore be called twice.
#
$i = 0;
Net::Pcap::Reassemble::loop($pcap_t, -1, sub {$i++}, "");
Net::Pcap::close($pcap_t);
$pcap_t = undef;
Net::Pcap::Reassemble::flush();

if ($i == 2) {
	print "ok 5\n";
} else {
	print "not ok 5\n";
}

#
# Test 6: Detach and attach to a different dump file.
#
$pcap_t = Net::Pcap::open_offline("t/linux_sll.pcap", \$err);
if (!defined($pcap_t)) {
	print "not ok 6\n";
	exit 1;
}
print "ok 6\n";

#
# Test 7: Read from a LINUX_SLL dump file. It contains one whole datagram
#         and one datagram in three fragments. The callback should
#         therefore be called twice.
#
$i = 0;
Net::Pcap::Reassemble::loop($pcap_t, -1, sub {$i++}, "");
Net::Pcap::close($pcap_t);
$pcap_t = undef;
Net::Pcap::Reassemble::flush();

if ($i == 2) {
	print "ok 7\n";
} else {
	print "not ok 7\n";
}
