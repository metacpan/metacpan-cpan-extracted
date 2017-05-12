#!/usr/bin/perl
#
# $Id: sinfp3-decode-netcat.pl,v 266b5bb31708 2012/11/22 19:10:18 gomor $
#
use strict;
use warnings;

use Net::Frame::Layer::SinFP3 qw(:consts);
use Net::Frame::Layer::SinFP3::Tlv;
use Net::Frame::Simple;

my $read = "";

while (my $line = <>) {
   $read .= $line;
}

my $frame = Net::Frame::Simple->new(
   raw        => $read,
   firstLayer => 'SinFP3',
);

print $frame->print,"\n";
