use Test;
BEGIN { plan(tests => 1) }

use Net::Frame::Layer::ICMPv6::MLD qw(:consts);
use Net::Frame::Layer::ICMPv6::MLD::Query;
use Net::Frame::Layer::ICMPv6::MLD::Report;
use Net::Frame::Layer::ICMPv6::MLD::Report::Record;

ok(1);
