use Test;
BEGIN { plan(tests => 1) }

use Net::Frame::Layer::IPv6 qw(:consts);
use Net::Frame::Layer::IPv6::Fragment;
use Net::Frame::Layer::IPv6::Routing;
use Net::Frame::Layer::IPv6::HopByHop;
use Net::Frame::Layer::IPv6::Option;
use Net::Frame::Layer::IPv6::Destination;

for my $m (qw(
   Net::Frame::Layer::IPv6::Fragment
   Net::Frame::Layer::IPv6::Routing
   Net::Frame::Layer::IPv6::HopByHop
   Net::Frame::Layer::IPv6::Option
   Net::Frame::Layer::IPv6::Destination
)) {
   my $l = $m->new;
   $l->pack;
   $l->unpack;
}

ok(1);
