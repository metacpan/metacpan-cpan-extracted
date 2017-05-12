use Test;
BEGIN { plan(tests => 1) }

use Net::Frame::Layer::IPv6 qw(:consts);
use Net::Frame::Layer::IPv6::Fragment;
use Net::Frame::Layer::IPv6::Routing;
use Net::Frame::Layer::IPv6::HopByHop;
use Net::Frame::Layer::IPv6::Option;
use Net::Frame::Layer::IPv6::Destination;

ok(1);
