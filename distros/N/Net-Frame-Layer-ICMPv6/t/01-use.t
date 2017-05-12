use Test;
BEGIN { plan(tests => 1) }

use Net::Frame::Layer::ICMPv6 qw(:consts);
use Net::Frame::Layer::ICMPv6::Echo;
use Net::Frame::Layer::ICMPv6::NeighborAdvertisement;
use Net::Frame::Layer::ICMPv6::NeighborSolicitation;
use Net::Frame::Layer::ICMPv6::RouterAdvertisement;
use Net::Frame::Layer::ICMPv6::RouterSolicitation;
use Net::Frame::Layer::ICMPv6::Option;
use Net::Frame::Layer::ICMPv6::TooBig;
use Net::Frame::Layer::ICMPv6::ParameterProblem;
use Net::Frame::Layer::ICMPv6::DestUnreach;
use Net::Frame::Layer::ICMPv6::TimeExceed;
use Net::Frame::Layer::ICMPv6;

ok(1);
