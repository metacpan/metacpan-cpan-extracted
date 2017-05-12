#!/usr/bin/perl
use strict;
use warnings;

my $target = shift || die("Specify target\n");

use Net::Frame::Device;

my $d = Net::Frame::Device->new(target => $target);
print $d->cgDumper."\n";
