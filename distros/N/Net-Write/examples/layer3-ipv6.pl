#!/usr/bin/perl
#
# $Id: layer3-ipv6.pl 2007 2015-01-27 06:26:42Z gomor $
#
use strict;
use warnings;

my $target = shift || die("Specify an IPv6 address as a parameter\n");
my $dev = shift || die("Specify an interface as a parameter\n");

use Net::Write::Layer qw(:constants);
use Net::Write::Layer3;

my $l3 = Net::Write::Layer3->new(
   dst => $target,
   family => NW_AF_INET6,
   dev => $dev,
);

use Net::Frame::Device;
use Net::Frame::Simple;
use Net::Frame::Layer::IPv6;
use Net::Frame::Layer::TCP;

my $device = Net::Frame::Device->new(
   target6 => $target,
   dev => $dev,
);

my $ip6 = Net::Frame::Layer::IPv6->new(
   dst => $target,
);
my $tcp = Net::Frame::Layer::TCP->new(
   dst => 22,
   options => "\x02\x04\x54\x0b",
);

my $oSimple = Net::Frame::Simple->new(
   layers => [ $ip6, $tcp ],
);

print $oSimple->print."\n";
print unpack('H*', $oSimple->raw)."\n";

$l3->open;
$l3->send($oSimple->raw);
$l3->close;
