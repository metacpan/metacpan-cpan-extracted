#!/usr/bin/perl
use strict;
use warnings;

use Net::Frame::Layer::IPv4 qw(:consts);
use Net::Frame::Layer::OSPF;
use Net::Frame::Simple;

my $ip = Net::Frame::Layer::IPv4->new(
   protocol => NF_IPv4_PROTOCOL_OSPF,
);
my $ospf = Net::Frame::Layer::OSPF->new;

my $oSimple = Net::Frame::Simple->new(
   layers => [ $ip, $ospf, ],
);

print $oSimple->print."\n";
print unpack('H*', $oSimple->raw)."\n";
