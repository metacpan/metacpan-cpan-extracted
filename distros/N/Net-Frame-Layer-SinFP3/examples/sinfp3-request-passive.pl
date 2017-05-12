#!/usr/bin/perl
#
# $Id: sinfp3-request-passive.pl 2 2012-11-14 21:14:07Z gomor $
#
use strict;
use warnings;

use Net::Frame::Layer::SinFP3 qw(:consts);
use Net::Frame::Layer::SinFP3::Tlv;
use Net::Frame::Simple;

# TLV TCP frame type
my $tlv1 = Net::Frame::Layer::SinFP3::Tlv->new(
   type  => NF_SINFP3_TLV_TYPE_FRAMEPROTOCOL,
   value => pack('C', NF_SINFP3_TLV_VALUE_IPv4),
   #value => NF_SINFP3_TLV_VALUE_IPv4,
);

# TLV passive frame data
my $tlv2 = Net::Frame::Layer::SinFP3::Tlv->new(
   type  => NF_SINFP3_TLV_TYPE_FRAMEPASSIVE,
   value => ("A"x44),
);

# Passive request
my $req = Net::Frame::Layer::SinFP3->new(
   type    => NF_SINFP3_TYPE_REQUESTPASSIVE,
   flags   => NF_SINFP3_FLAG_OS|NF_SINFP3_FLAG_OSVERSION|NF_SINFP3_FLAG_OSVERSIONFAMILY|NF_SINFP3_FLAG_MATCHSCORE,
   code    => NF_SINFP3_CODE_SUCCESSUNKNOWN,
   tlvList => [ $tlv1, $tlv2, ],
);

my $frame = Net::Frame::Simple->new(
   layers => [ $req, ],
);

print $frame->print,"\n";

print "RAW: ".unpack("H*", $frame->raw)."\n";
