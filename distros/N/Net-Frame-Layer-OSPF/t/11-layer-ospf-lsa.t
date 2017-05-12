use Test;
BEGIN { plan(tests => 1) }

use Net::Frame::Layer::OSPF::Lsa;

my $l = Net::Frame::Layer::OSPF::Lsa->new;
$l->pack;
$l->unpack;

ok(1);
