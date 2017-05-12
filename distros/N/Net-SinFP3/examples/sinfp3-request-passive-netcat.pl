#!/usr/bin/perl
#
# $Id: sinfp3-request-passive-netcat.pl,v a9e6197e741c 2012/11/15 13:03:10 gomor $
#
use strict;
use warnings;

use Net::Frame::Layer::SinFP3 qw(:consts);
use Net::Frame::Layer::SinFP3::Tlv;
use Net::Frame::Simple;

# TLV TCP frame type
my $tlv1 = Net::Frame::Layer::SinFP3::Tlv->new(
   type  => NF_SINFP3_TLV_TYPE_FRAMEPROTOCOL,
   value => pack("C", NF_SINFP3_TLV_VALUE_IPv4),
);

# TLV passive frame data
my $tlv2 = Net::Frame::Layer::SinFP3::Tlv->new(
   type  => NF_SINFP3_TLV_TYPE_FRAMEPASSIVE,
   value => pack("H*", "4500003c54e6400040068b73ac100102ac100140dd3d014d605f693400000000a002ffff515d0000020405b4010303030402080a0b97e88e00000000"),
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

print $frame->raw;
