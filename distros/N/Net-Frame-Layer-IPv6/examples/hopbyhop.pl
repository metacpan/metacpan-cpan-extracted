#!/usr/bin/perl
use strict;
use warnings;

use Net::Frame 1.09;
use Net::Frame::Simple 1.05;
use Net::Frame::Layer qw(:subs);
use Net::Frame::Layer::ETH qw(:consts);
use Net::Frame::Layer::IPv6 qw(:consts);
use Net::Frame::Layer::IPv6::HopByHop;
use Net::Frame::Layer::IPv6::Option;
use Net::Frame::Layer::ICMPv6 qw(:consts);
use Net::Frame::Layer::ICMPv6::Echo;

# Get input
print "What host to MLD query? ";
my $dest = <STDIN>;
chomp $dest;
print "\n";

# Validate
$dest = $dest || 'fe80::1';
if (!($dest = getHostIpv6Addr($dest))) { return }

# Create layers
my $ether = Net::Frame::Layer::ETH->new(
    type => NF_ETH_TYPE_IPv6,
);
my $ipv6 = Net::Frame::Layer::IPv6->new(
    src        => 'fe80::2',
    dst        => $dest,
    nextHeader => NF_IPv6_PROTOCOL_IPv6HOPBYHOP,
    hopLimit   => 1,
);

# Hop by Hop options
my $option = Net::Frame::Layer::IPv6::Option->new(
    type  => 5,
    value => pack "H*", '0000',
);
my $PadN = Net::Frame::Layer::IPv6::Option->new;

my $hop = Net::Frame::Layer::IPv6::HopByHop->new(
    nextHeader => NF_IPv6_PROTOCOL_ICMPv6,
    options    => [ $option, $PadN ],
);

# MLD (ICMPv6)
my $icmpv6 = Net::Frame::Layer::ICMPv6->new(
    type => 128,
);
my $mld = Net::Frame::Layer::ICMPv6::Echo->new(
    identifier     => 16,
    sequenceNumber => 0,
    payload        => inet6Aton('::'),
);

# Create packet
my $packet = Net::Frame::Simple->new(
   layers => [ $ether, $ipv6, $hop, $icmpv6, $mld, ],
);

print $packet->print."\n";

my $raw = $packet->pack;

my $unpack = Net::Frame::Simple->new(
   firstLayer => 'ETH',
   raw        => $raw,
);

print $unpack->print."\n";
