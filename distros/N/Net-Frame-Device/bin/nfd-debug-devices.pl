#!/usr/bin/perl
#
# $Id: nfd-debug-devices.pl 354 2012-11-16 15:28:51Z gomor $
#
use strict;
use warnings;

use Net::Frame::Device;

Net::Frame::Device::debugDeviceList;
print "\n";
