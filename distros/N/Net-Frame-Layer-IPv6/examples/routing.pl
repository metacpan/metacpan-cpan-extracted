#!/usr/bin/perl

use strict;
use warnings;

use Net::Frame 1.09;
use Net::Frame::Simple 1.05;
use Net::Frame::Layer qw(:subs);
use Net::Frame::Layer::ETH qw(:consts);
use Net::Frame::Layer::IPv6 qw(:consts);
use Net::Frame::Layer::IPv6::Routing;
use Net::Frame::Layer::ICMPv6 qw(:consts);
use Net::Frame::Layer::ICMPv6::Echo;

# Get input
print "What destination [ENTER for default]? ";
my $dest = <STDIN>;
chomp $dest;
print "What hop1 [ENTER for default]?        ";
my $hop1 = <STDIN>;
chomp $hop1;
print "What hop2 [ENTER for default]?        ";
my $hop2 = <STDIN>;
chomp $hop2;
print "\n";

# Validate
$dest = $dest || 'ipv6.google.com';
if (!($dest = getHostIpv6Addr($dest))) { return }
$hop1 = $hop1 || '2001::1';
if (!($hop1 = getHostIpv6Addr($hop1))) { return }
$hop2 = $hop2 || '2001::2';
if (!($hop2 = getHostIpv6Addr($hop2))) { return }

# Create layers
my $ether = Net::Frame::Layer::ETH->new(
    type=>NF_ETH_TYPE_IPv6
);
my $ipv6  = Net::Frame::Layer::IPv6->new(
    dst        => $hop1,
    nextHeader => NF_IPv6_PROTOCOL_IPv6ROUTING
);
my $route = Net::Frame::Layer::IPv6::Routing->new(
    nextHeader => NF_IPv6_PROTOCOL_ICMPv6,
    addresses  => [
        $hop2, $dest
    ],
);
my $icmp  = Net::Frame::Layer::ICMPv6->new;
my $echo  = Net::Frame::Layer::ICMPv6::Echo->new(
    payload=>'echo'
);

# Create packet
my $packet = Net::Frame::Simple->new(layers=>
    [ $ether, $ipv6, $route, $icmp, $echo ]
);

print $packet->print . "\n";
