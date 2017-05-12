use Test;
BEGIN { plan(tests => 1) }

use Net::Frame::Layer::LLTD qw(:consts);
use Net::Frame::Layer::LLTD::Discover;
use Net::Frame::Layer::LLTD::Hello;
use Net::Frame::Layer::LLTD::Emit;
use Net::Frame::Layer::LLTD::Tlv;
use Net::Frame::Layer::LLTD::EmiteeDesc;
use Net::Frame::Layer::LLTD::QueryResp;
use Net::Frame::Layer::LLTD::RecveeDesc;

ok(1);
