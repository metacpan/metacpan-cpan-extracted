use Test;
BEGIN { plan(tests => 1) }

use Net::Frame::Layer::ICMPv4 qw(:consts);
use Net::Frame::Layer::ICMPv4::AddressMask;
use Net::Frame::Layer::ICMPv4::Echo;
use Net::Frame::Layer::ICMPv4::Redirect;
use Net::Frame::Layer::ICMPv4::Timestamp;
use Net::Frame::Layer::ICMPv4::DestUnreach;
use Net::Frame::Layer::ICMPv4::Information;
use Net::Frame::Layer::ICMPv4::TimeExceed;

ok(1);
