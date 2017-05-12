#!/usr/bin/perl
use strict;
use warnings;

use Net::Frame::Layer::ETH qw(:consts);
use Net::Frame::Layer::PPPoES qw(:consts);
use Net::Frame::Layer::PPPLCP;
use Net::Frame::Simple;

my $eth = Net::Frame::Layer::ETH->new(
   type => NF_ETH_TYPE_PPPoES,
);
my $pppoes = Net::Frame::Layer::PPPoES->new(
   pppProtocol => NF_PPPoE_PPP_PROTOCOL_PPPLCP,
);
my $ppplcp = Net::Frame::Layer::PPPLCP->new;

my $oSimple = Net::Frame::Simple->new(
   layers => [ $eth, $pppoes, $ppplcp, ],
);

print $oSimple->print."\n";
print unpack('H*', $oSimple->raw)."\n";
