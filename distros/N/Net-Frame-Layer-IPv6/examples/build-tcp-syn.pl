#!/usr/bin/perl
use strict;
use warnings;

use Net::Frame::Layer::ETH qw(:consts);
use Net::Frame::Layer::IPv6;
use Net::Frame::Layer::TCP;
use Net::Frame::Simple;

my $eth = Net::Frame::Layer::ETH->new(
   src  => '00:13:A9:2C:5B:A3',
   dst  => '00:0c:29:1d:c9:21',
   type => NF_ETH_TYPE_IPv6,
);
my $ip6 = Net::Frame::Layer::IPv6->new(
   src => 'fe80::213:a9ff:fe2c:5ba3',
   dst => 'fe80::20c:29ff:fe1d:c921',
);
my $tcp = Net::Frame::Layer::TCP->new(
   options => "\x02\x04\x54\x0b",
);

my $oSimple = Net::Frame::Simple->new(
   layers => [ $eth, $ip6, $tcp ],
);

print $oSimple->print."\n";
print unpack('H*', $oSimple->raw)."\n";
