use Test;
BEGIN { plan(tests => 1) }

use Net::Frame::Layer::OSPF::LinkStateRequest;

my $l = Net::Frame::Layer::OSPF::LinkStateRequest->new;
$l->pack;
$l->unpack;

ok(1);
