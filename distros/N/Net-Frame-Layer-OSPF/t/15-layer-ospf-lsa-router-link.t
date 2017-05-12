use Test;
BEGIN { plan(tests => 1) }

use Net::Frame::Layer::OSPF::Lsa::Router::Link;

my $l = Net::Frame::Layer::OSPF::Lsa::Router::Link->new;
$l->pack;
$l->unpack;

ok(1);
