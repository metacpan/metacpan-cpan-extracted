#!/usr/bin/perl -w

BEGIN { $| = 1; print "1..52\n";}
use Net::Netmask;
$loaded = 1;
print "ok 1\n";
END {print "not ok 1\n" unless $loaded;}

sub test {
	local($^W)=0;
	my($num,$true,$msg)=@_;
	print($true ? "ok $num\n" : "not ok $num $msg\n");
}
################################################################################

use strict;

my $debug = 0;

test(2,Net::Netmask->debug($debug)==$debug,"unable to set debug");


# test a variety of ip's with bytes greater than 255.
# all these tests should return undef

test(3,!defined(Net::Netmask->new2('209.256.68.22:255.255.224.0')), 
	"bad net byte");
test(4,scalar(Net::Netmask->errstr =~ /^could not parse /),"errstr mismatch");
test(5,!defined(Net::Netmask->new2('209.180.68.22:256.255.224.0')), 
	"bad mask byte");
test(6,scalar(Net::Netmask->errstr =~ /^illegal netmask:/),"errstr mismatch");
test(7,!defined(Net::Netmask->new2('209.157.300.22','255.255.224.0')), 
	"bad net byte");
test(8,scalar(Net::Netmask->errstr =~ /^could not parse /),"errstr mismatch");
test(9,!defined(Net::Netmask->new2('300.157.70.33','0xffffe000')), 
	"bad net byte");
test(10,scalar(Net::Netmask->errstr =~ /^could not parse /),"errstr mismatch");
test(11,!defined(Net::Netmask->new2('209.500.70.33/19')), "bad net byte");
test(12,scalar(Net::Netmask->errstr =~ /^could not parse /),"errstr mismatch");
test(13,!defined(Net::Netmask->new2('140.999.82')),       "bad net byte");
test(14,scalar(Net::Netmask->errstr =~ /^could not parse /),"errstr mismatch");
test(15,!defined(Net::Netmask->new2('899.174')),          "bad net byte");
test(16,scalar(Net::Netmask->errstr =~ /^could not parse /),"errstr mismatch");
test(17,!defined(Net::Netmask->new2('900')),              "bad net byte");
test(18,scalar(Net::Netmask->errstr =~ /^could not parse /),"errstr mismatch");
test(19,!defined(Net::Netmask->new2('209.157.300/19')),   "bad net byte");
test(20,scalar(Net::Netmask->errstr =~ /^could not parse /),"errstr mismatch");
test(21,!defined(Net::Netmask->new2('209.300.64.0-209.157.95.255')),
	"bad net byte");
test(22,scalar(Net::Netmask->errstr =~ /^illegal dotted quad/),
	"errstr mismatch");
test(23,!defined(Net::Netmask->new2('209.300/17')),       "bad net byte");
test(24,scalar(Net::Netmask->errstr =~ /^could not parse /),"errstr mismatch");

# test whois numbers with space between dash

test(25,Net::Netmask->new2('209.157.64.0 - 209.157.95.255'),
	"whois with single space around dash");
test(26,Net::Netmask->new2('209.157.64.0   -   209.157.95.255'),
	"whois with mulitple spaces around dash");

# test ranges that are a power-of-two big, but are not legal blocks
test(27,! Net::Netmask->new2('218.0.0.0 - 221.255.255.255'),
	"could not find exact fit for 218.0.0.0 - 221.255.255.255");
test(28,scalar(Net::Netmask->errstr =~ /^could not find exact fit/),
	"errstr mismatch");
test(29,! Net::Netmask->new2('218.0.0.4 - 218.0.0.11'),
	"could not find exact fit for 218.0.0.4 - 218.0.0.11");
test(30,scalar(Net::Netmask->errstr =~ /^could not find exact fit/),
	"errstr mismatch");

# test some more bad nets/masks
test(31,!defined(Net::Netmask->new2('10.10.10.10#256.0.0.0')),"bad mask byte");
test(32,scalar(Net::Netmask->errstr =~ /^illegal hostmask:/),"errstr mismatch");
test(33,!defined(Net::Netmask->new2('209.157.200.22','256.255.224.0')),
	"bad mask");
test(34,scalar(Net::Netmask->errstr =~ /^illegal netmask:/),"errstr mismatch");
test(35,!defined(Net::Netmask->new2('10.10.10.10','0xF')),"bad mask");
test(36,scalar(Net::Netmask->errstr =~ /^illegal netmask:/),"errstr mismatch");
test(37,!defined(Net::Netmask->new2('209.200.70.33/33')), "bad mask");
test(38,scalar(Net::Netmask->errstr =~ /^illegal number of bits:/),"errstr mismatch");
test(39,!defined(Net::Netmask->new2('209.200.64.0-309.157.95.255')),
	"bad mask byte");
test(40,scalar(Net::Netmask->errstr =~ /^illegal dotted quad/),
	"errstr mismatch");

# test completely invalid args
test(41,!defined(Net::Netmask->new2('foo')),"bad net");
test(42,scalar(Net::Netmask->errstr =~ /^could not parse /),"errstr mismatch");
test(43,!defined(Net::Netmask->new2('10.10.10.10','foo')),"bad mask");
test(44,scalar(Net::Netmask->errstr =~ /^could not parse /),"errstr mismatch");
test(45,!defined(Net::Netmask->new2('10.10.10','foo')),"bad mask");
test(46,scalar(Net::Netmask->errstr =~ /^could not parse /),"errstr mismatch");
test(47,!defined(Net::Netmask->new2('10.10','foo')),"bad mask");
test(48,scalar(Net::Netmask->errstr =~ /^could not parse /),"errstr mismatch");
test(49,!defined(Net::Netmask->new2('10','foo')),"bad mask");
test(50,scalar(Net::Netmask->errstr =~ /^could not parse /),"errstr mismatch");
test(51,!defined(Net::Netmask->new2('10.10.10.10','0xYYY')),"bad mask");
test(52,scalar(Net::Netmask->errstr =~ /^could not parse/),"errstr mismatch");

