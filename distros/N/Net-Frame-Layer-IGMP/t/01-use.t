use Test;
BEGIN { plan(tests => 1) }

use Net::Frame::Layer::IGMP qw(:consts);
use Net::Frame::Layer::IGMP::v3Query;
use Net::Frame::Layer::IGMP::v3Report qw(:consts);

ok(1);
