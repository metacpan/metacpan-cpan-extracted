#!/usr/bin/perl
use strict;
use warnings;

use Net::Frame::Layer::IPv4;
use Net::Frame::Layer::TCP;
use Net::Frame::Simple;

my $ip4 = Net::Frame::Layer::IPv4->new;
my $tcp = Net::Frame::Layer::TCP->new(
   options => "\x02\x04\x54\x0b",
);

my $oSimple = Net::Frame::Simple->new(
   layers => [ $ip4, $tcp ],
);

print unpack('H*', $oSimple->raw)."\n";
