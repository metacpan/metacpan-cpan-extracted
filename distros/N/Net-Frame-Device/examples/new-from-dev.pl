#!/usr/bin/perl
use strict;
use warnings;

my $dev = shift || die("Specify network interface\n");

use Net::Frame::Device;

my $d = Net::Frame::Device->new(dev => $dev);
print $d->cgDumper."\n";
