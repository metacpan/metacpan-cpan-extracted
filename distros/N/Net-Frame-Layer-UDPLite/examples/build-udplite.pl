#!/usr/bin/perl
use strict;
use warnings;

use Net::Frame::Layer::UDPLite;
use Net::Frame::Simple;

my $l = Net::Frame::Layer::UDPLite->new;

my $oSimple = Net::Frame::Simple->new(
   layers => [ $l ],
);

print $oSimple->print."\n";
my $raw = $oSimple->raw;
print unpack('H*', $raw)."\n";
print "LEN: ".length($raw)."\n";
