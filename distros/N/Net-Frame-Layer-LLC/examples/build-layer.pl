#!/usr/bin/perl
use strict;
use warnings;

use Net::Frame::Layer::ETH;
use Net::Frame::Layer::LLC;
use Net::Frame::Layer::STP;
use Net::Frame::Simple;

my $eth = Net::Frame::Layer::ETH->new;
my $llc = Net::Frame::Layer::LLC->new;
my $stp = Net::Frame::Layer::STP->new;

my $oSimple = Net::Frame::Simple->new(
   layers => [ $eth, $llc, $stp ],
);

print $oSimple->print."\n";
print unpack('H*', $oSimple->raw)."\n";
