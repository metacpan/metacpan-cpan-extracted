use Test;
BEGIN { plan(tests => 1) }

use Net::Frame::Layer::OSPF qw(:consts);
use Net::Frame::Layer::OSPF::Hello;
use Net::Frame::Layer::OSPF::Lsa;
use Net::Frame::Layer::OSPF::LinkStateUpdate;

ok(1);
