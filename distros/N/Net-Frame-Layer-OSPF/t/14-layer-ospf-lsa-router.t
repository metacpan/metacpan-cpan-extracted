use Test;
BEGIN { plan(tests => 1) }

use Net::Frame::Layer::OSPF::Lsa::Router;

my $l = Net::Frame::Layer::OSPF::Lsa::Router->new;
$l->pack;
$l->unpack;

ok(1);
