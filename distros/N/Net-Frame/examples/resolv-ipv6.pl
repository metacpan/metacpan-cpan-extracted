#!/usr/bin/perl
use strict;
use warnings;

use Net::Frame::Layer qw(:subs);

print getHostIpv6Addr('www.google.com')."\n";
