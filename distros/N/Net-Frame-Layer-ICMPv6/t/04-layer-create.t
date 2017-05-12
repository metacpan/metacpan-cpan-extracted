use Test;
BEGIN { plan(tests => 1) }

use Net::Frame::Layer::ICMPv6 qw(:consts);
use Net::Frame::Layer::ICMPv6::DestUnreach;
use Net::Frame::Layer::ICMPv6::Echo;
use Net::Frame::Layer::ICMPv6::NeighborAdvertisement;
use Net::Frame::Layer::ICMPv6::NeighborSolicitation;
use Net::Frame::Layer::ICMPv6::ParameterProblem;
use Net::Frame::Layer::ICMPv6::RouterSolicitation;
use Net::Frame::Layer::ICMPv6::RouterAdvertisement;
use Net::Frame::Layer::ICMPv6::TimeExceed;
use Net::Frame::Layer::ICMPv6::TooBig;
use Net::Frame::Layer::ICMPv6::Option;

for my $m (qw(
   Net::Frame::Layer::ICMPv6
   Net::Frame::Layer::ICMPv6::DestUnreach
   Net::Frame::Layer::ICMPv6::Echo
   Net::Frame::Layer::ICMPv6::NeighborAdvertisement
   Net::Frame::Layer::ICMPv6::NeighborSolicitation
   Net::Frame::Layer::ICMPv6::ParameterProblem
   Net::Frame::Layer::ICMPv6::RouterSolicitation
   Net::Frame::Layer::ICMPv6::RouterAdvertisement
   Net::Frame::Layer::ICMPv6::TimeExceed
   Net::Frame::Layer::ICMPv6::TooBig
   Net::Frame::Layer::ICMPv6::Option
)) {
   my $l = $m->new;
   $l->pack;
   $l->unpack;
}

ok(1);
