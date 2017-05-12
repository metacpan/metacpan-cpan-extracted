#!/usr/bin/perl
use strict;
use warnings;

my $target = shift || die("Specify target\n");

use Net::Frame::Device;

my $oDevice = Net::Frame::Device->new(target => $target);
print $oDevice->cgDumper."\n";

my $mac = $oDevice->lookupMac($target);
print "MAC: $mac\n" if $mac;
