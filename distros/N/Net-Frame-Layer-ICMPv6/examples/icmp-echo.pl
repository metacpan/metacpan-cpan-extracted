#!/usr/bin/perl
use strict;
use warnings;

use Net::Frame::Simple;
use Net::Frame::Layer::ETH qw(:consts);
use Net::Frame::Layer::IPv6 qw(:consts);
use Net::Frame::Layer::ICMPv6;
use Net::Frame::Layer::ICMPv6::Echo;

my $eth = Net::Frame::Layer::ETH->new(type => NF_ETH_TYPE_IPv6);

my $ip = Net::Frame::Layer::IPv6->new(nextHeader => NF_IPv6_PROTOCOL_ICMPv6);

my $icmp = Net::Frame::Layer::ICMPv6->new;
my $echo = Net::Frame::Layer::ICMPv6::Echo->new(payload => 'test');

my $oSimple = Net::Frame::Simple->new(
   layers => [ $eth, $ip, $icmp, $echo, ],
);
print $oSimple->print."\n";
print unpack('H*', $oSimple->raw)."\n";

my $oSimple2 = Net::Frame::Simple->new(
   raw        => $oSimple->raw,
   firstLayer => 'ETH',
);
print $oSimple2->print."\n";
print unpack('H*', $oSimple2->raw)."\n";
