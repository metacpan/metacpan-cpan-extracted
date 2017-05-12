#!/usr/bin/perl
use strict;
use warnings;

use Net::Frame::Layer::ETH qw(:consts);
use Net::Frame::Layer::PPPoES;
use Net::Frame::Simple;

my $eth = Net::Frame::Layer::ETH->new(
   type => NF_ETH_TYPE_PPPoES,
);
my $pppoes = Net::Frame::Layer::PPPoES->new;

my $oSimple = Net::Frame::Simple->new(
   layers => [ $eth, $pppoes, ],
);

print $oSimple->print."\n";
print unpack('H*', $oSimple->raw)."\n";
