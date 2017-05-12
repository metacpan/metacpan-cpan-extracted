#!/usr/bin/perl
#
# $Id: sinfp3-response-passive.pl 5 2012-11-18 15:05:35Z gomor $
#
use strict;
use warnings;

use Net::Frame::Layer::SinFP3 qw(:consts);
use Net::Frame::Layer::SinFP3::Tlv;
use Net::Frame::Simple;

# TLV result1
my $tlv1 = Net::Frame::Layer::SinFP3::Tlv->new(
   type  => NF_SINFP3_TLV_TYPE_OS,
   value => 'Linux',
);
my $tlv2 = Net::Frame::Layer::SinFP3::Tlv->new(
   type  => NF_SINFP3_TLV_TYPE_OSVERSION,
   value => '2.6.x',
);
my $tlv3 = Net::Frame::Layer::SinFP3::Tlv->new(
   type  => NF_SINFP3_TLV_TYPE_OSVERSIONFAMILY,
   value => '2.6.x',
);
my $tlv4 = Net::Frame::Layer::SinFP3::Tlv->new(
   type  => NF_SINFP3_TLV_TYPE_MATCHSCORE,
   value => pack('C', 100),
);

# TLV result2
my $tlv5 = Net::Frame::Layer::SinFP3::Tlv->new(
   type  => NF_SINFP3_TLV_TYPE_OS,
   value => 'Linux',
);
my $tlv6 = Net::Frame::Layer::SinFP3::Tlv->new(
   type  => NF_SINFP3_TLV_TYPE_OSVERSION,
   value => '2.4.x',
);
my $tlv7 = Net::Frame::Layer::SinFP3::Tlv->new(
   type  => NF_SINFP3_TLV_TYPE_OSVERSIONFAMILY,
   value => '2.4.x',
);
my $tlv8 = Net::Frame::Layer::SinFP3::Tlv->new(
   type  => NF_SINFP3_TLV_TYPE_MATCHSCORE,
   value => pack('C', 100),
);

# Passive response
my $response = Net::Frame::Layer::SinFP3->new(
   type    => NF_SINFP3_TYPE_RESPONSEPASSIVE,
   flags   => NF_SINFP3_FLAG_OS|NF_SINFP3_FLAG_OSVERSION|NF_SINFP3_FLAG_OSVERSIONFAMILY|NF_SINFP3_FLAG_MATCHSCORE,
   code    => NF_SINFP3_CODE_SUCCESSRESULT,
   tlvList => [ $tlv1, $tlv2, $tlv3, $tlv4, $tlv5, $tlv6, $tlv7, $tlv8, ],
);

my $frame = Net::Frame::Simple->new(
   layers => [ $response, ],
);

print $frame->print,"\n";

print "RAW: ".unpack("H*", $frame->raw)."\n";
