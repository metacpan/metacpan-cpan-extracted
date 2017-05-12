use Test;
BEGIN { plan(tests => 1) }

use Net::Frame::Layer::OSPF::Lsa::Network;

my $l = Net::Frame::Layer::OSPF::Lsa::Network->new;
$l->pack;
$l->unpack;

ok(1);
