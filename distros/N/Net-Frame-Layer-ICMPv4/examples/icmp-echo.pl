#!/usr/bin/perl
use strict;
use warnings;

use Net::Frame::Simple;
use Net::Frame::Layer::IPv4 qw(:consts);
use Net::Frame::Layer::ICMPv4;
use Net::Frame::Layer::ICMPv4::Echo;

my $ip = Net::Frame::Layer::IPv4->new(protocol => NF_IPv4_PROTOCOL_ICMPv4);

my $icmp = Net::Frame::Layer::ICMPv4->new;
my $type = Net::Frame::Layer::ICMPv4::Echo->new(payload => 'test');

my $oSimple = Net::Frame::Simple->new(
   layers => [ $ip, $icmp, $type, ],
);
print $oSimple->print."\n";
print unpack('H*', $oSimple->raw)."\n";

my $oSimple2 = Net::Frame::Simple->new(
   raw        => $oSimple->raw,
   firstLayer => 'IPv4',
);
print $oSimple2->print."\n";
print unpack('H*', $oSimple2->raw)."\n";
