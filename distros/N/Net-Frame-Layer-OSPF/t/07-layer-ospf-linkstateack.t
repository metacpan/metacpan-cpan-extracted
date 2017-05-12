use Test;
BEGIN { plan(tests => 1) }

use Net::Frame::Layer::OSPF::LinkStateAck;

my $l = Net::Frame::Layer::OSPF::LinkStateAck->new;
$l->pack;
$l->unpack;

ok(1);
