use Test;
BEGIN { plan(tests => 1) }

use Net::Frame::Layer::OSPF::LinkStateUpdate;

my $l = Net::Frame::Layer::OSPF::LinkStateUpdate->new;
$l->pack;
$l->unpack;

ok(1);
