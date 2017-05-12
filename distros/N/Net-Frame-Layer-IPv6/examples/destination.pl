#!/usr/bin/perl
use strict;
use warnings;

use Net::Frame 1.09;
use Net::Frame::Simple 1.05;
use Net::Frame::Layer qw(:subs);
use Net::Frame::Layer::ETH qw(:consts);
use Net::Frame::Layer::IPv6 qw(:consts);
use Net::Frame::Layer::IPv6::Destination;
use Net::Frame::Layer::IPv6::Option;
use Net::Frame::Layer::ICMPv6 qw(:consts);
use Net::Frame::Layer::ICMPv6::Echo;

# Get input
print "What destination [ENTER for default]? ";
my $dest = <STDIN>;
chomp $dest;
print "\n";

# Validate
$dest = $dest || 'ipv6.google.com';
if (!($dest = getHostIpv6Addr($dest))) { return }

# Create layers
my $ether = Net::Frame::Layer::ETH->new(
    type => NF_ETH_TYPE_IPv6,
);
my $ipv6 = Net::Frame::Layer::IPv6->new(
    dst        => $dest,
    nextHeader => NF_IPv6_PROTOCOL_IPv6DESTINATION,
);

# Destination options
my $option = Net::Frame::Layer::IPv6::Option->new(
    type  => 1,
    value => pack("H*", '00000000'),
);
my $option2 = Net::Frame::Layer::IPv6::Option->new(
    type  => 1,
    value => pack("H*", '000000000000'),
);

my $destination = Net::Frame::Layer::IPv6::Destination->new(
    nextHeader => NF_IPv6_PROTOCOL_ICMPv6,
    options    => [ $option, $option2, ],
);

# MLD (ICMPv6)
my $icmpv6 = Net::Frame::Layer::ICMPv6->new;
my $echo = Net::Frame::Layer::ICMPv6::Echo->new(
    identifier     => 16,
    sequenceNumber => 0,
    payload        =>'echo',
);

# Create packet
my $packet = Net::Frame::Simple->new(
   layers => [ $ether, $ipv6, $destination, $icmpv6, $echo, ],
);

print $packet->print."\n";

my $raw = $packet->pack;
my $unpack = Net::Frame::Simple->new(
   firstLayer => 'ETH',
   raw        => $raw,
);

print $unpack->print."\n";
