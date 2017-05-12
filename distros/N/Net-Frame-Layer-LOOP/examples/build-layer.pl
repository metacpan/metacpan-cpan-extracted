#!/usr/bin/perl
use strict;
use warnings;

use Net::Frame::Layer::ETH qw(:consts);
use Net::Frame::Layer::LOOP;
use Net::Frame::Simple;

my $eth  = Net::Frame::Layer::ETH->new(
   type => NF_ETH_TYPE_LOOP,
);
my $loop = Net::Frame::Layer::LOOP->new;

my $oSimple = Net::Frame::Simple->new(
   layers => [ $eth, $loop, ],
);

print $oSimple->print."\n";
print unpack('H*', $oSimple->raw)."\n";
