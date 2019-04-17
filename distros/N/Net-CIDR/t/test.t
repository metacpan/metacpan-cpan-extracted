# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..14\n"; }
END {print "not ok 1\n" unless $loaded;}
use Net::CIDR;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

{
    my @octet_list=Net::CIDR::cidr2octets("10.0.0.0/14", "192.168.0.0/24");

    push @octet_list, Net::CIDR::cidr2octets("::dead:beef:0:0/110");

    my @res=("10.0", "10.1", "10.2", "10.3", "192.168.0",
	     "0000:0000:0000:0000:dead:beef:0000",
	     "0000:0000:0000:0000:dead:beef:0001",
	     "0000:0000:0000:0000:dead:beef:0002",
	     "0000:0000:0000:0000:dead:beef:0003");

    if (join(" ", @octet_list) eq join(" ", @res))
    {
	print "ok 2\n";
    }
    else
    {
	print "not ok 2\n";
    }
}

if (join(" ", Net::CIDR::addr2cidr('192.168.0.31'))
    eq "192.168.0.31/32 192.168.0.30/31 192.168.0.28/30 192.168.0.24/29 192.168.0.16/28 192.168.0.0/27 192.168.0.0/26 192.168.0.0/25 192.168.0.0/24 192.168.0.0/23 192.168.0.0/22 192.168.0.0/21 192.168.0.0/20 192.168.0.0/19 192.168.0.0/18 192.168.0.0/17 192.168.0.0/16 192.168.0.0/15 192.168.0.0/14 192.168.0.0/13 192.160.0.0/12 192.160.0.0/11 192.128.0.0/10 192.128.0.0/9 192.0.0.0/8 192.0.0.0/7 192.0.0.0/6 192.0.0.0/5 192.0.0.0/4 192.0.0.0/3 192.0.0.0/2 128.0.0.0/1 0.0.0.0/0")
{
    print "ok 3\n";
}
else
{
    print "not ok 3\n";

    warn join(" ", Net::CIDR::addr2cidr('192.168.0.31'));
}

if (join("",
	 Net::CIDR::cidr2range("192.168.0.0/16")) eq "192.168.0.0-192.168.255.255"
    && join("", Net::CIDR::cidr2range("dead::beef::/46"))
    eq "dead:beef::-dead:beef:3:ffff:ffff:ffff:ffff:ffff")
{
    print "ok 4\n";
}
else
{
    print "not ok 4\n";
}

if (Net::CIDR::cidrvalidate("192.168.0.1") &&
    Net::CIDR::cidrvalidate("::ffff:192.168.0.1") &&
    Net::CIDR::cidrvalidate("192.168.0.0/24") &&
    Net::CIDR::cidrvalidate("::ffff:192.168.0.0/120"))
{
    print "ok 5\n";
}
else
{
    print "not ok 5\n";
}

if (Net::CIDR::cidrvalidate("192.168.0.1/24") ||
    Net::CIDR::cidrvalidate("::ffff:192.168.0.1/120"))
{
    print "not ok 6\n";
}
else
{
    print "ok 6\n";
}

if (Net::CIDR::cidrvalidate("dead:beef::") &&
    Net::CIDR::cidrvalidate("dead:beef::/32") &&
    Net::CIDR::cidrvalidate("dead:beef::/120"))
{
    print "ok 7\n";
}
else
{
    print "not ok 7\n";
}

if (Net::CIDR::cidrvalidate("dead:beef::/31"))
{
    print "not ok 8\n";
}
else
{
    print "ok 8\n";
}

if (join(" ", Net::CIDR::addr2cidr("192.168.0.31"))
    eq "192.168.0.31/32 192.168.0.30/31 192.168.0.28/30 192.168.0.24/29 192.168.0.16/28 192.168.0.0/27 192.168.0.0/26 192.168.0.0/25 192.168.0.0/24 192.168.0.0/23 192.168.0.0/22 192.168.0.0/21 192.168.0.0/20 192.168.0.0/19 192.168.0.0/18 192.168.0.0/17 192.168.0.0/16 192.168.0.0/15 192.168.0.0/14 192.168.0.0/13 192.160.0.0/12 192.160.0.0/11 192.128.0.0/10 192.128.0.0/9 192.0.0.0/8 192.0.0.0/7 192.0.0.0/6 192.0.0.0/5 192.0.0.0/4 192.0.0.0/3 192.0.0.0/2 128.0.0.0/1 0.0.0.0/0")
{
    print "ok 9\n";
}
else
{
    print "not ok 9\n";
}

if (Net::CIDR::cidrvalidate("1:1:000f:01:65:e:1111:eeee"))
{
    print "ok 10\n";
}
else
{
    print "not ok 10\n";
}

if (Net::CIDR::cidrvalidate("fe80:0:120::/44"))
{
    print "ok 11\n";
}
else
{
    print "not ok 11\n";
}

my @only4 = qw(
    10.0.0.0/24
    10.0.1.0/24
);

my @only6 = qw(
    2001:db8::/64
    2001:db8:1::/64
);

my @dualstack = qw(
    10.0.2.0/24
    2001:db8:2::/64
);

if (join("",
    Net::CIDR::cidrlookup("10.0.0.1", @only4),
    Net::CIDR::cidrlookup("10.0.10.1", @only4),
    Net::CIDR::cidrlookup("2001:db8::1", @only4)) eq "100")
{
    print "ok 12\n";
}
else
{
    print "not ok 12\n";
}

if (join("",
    Net::CIDR::cidrlookup("2001:db8::1", @only6),
    Net::CIDR::cidrlookup("2001:db8:a::1", @only6),
    Net::CIDR::cidrlookup("10.0.0.1", @only6)) eq "100")
{
    print "ok 13\n";
}
else
{
    print "not ok 13\n";
}

if (join("",
    Net::CIDR::cidrlookup("10.0.2.1", @dualstack),
    Net::CIDR::cidrlookup("10.0.20.1", @dualstack),
    Net::CIDR::cidrlookup("2001:db8:2::1", @dualstack),
    Net::CIDR::cidrlookup("2001:db8:20::1", @dualstack)))
{
    print "ok 14\n";
}
else
{
    print "not ok 14\n";
}
