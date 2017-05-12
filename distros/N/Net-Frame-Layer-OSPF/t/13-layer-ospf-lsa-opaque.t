use Test;
BEGIN { plan(tests => 1) }

use Net::Frame::Layer::OSPF::Lsa::Opaque;

my $l = Net::Frame::Layer::OSPF::Lsa::Opaque->new;
$l->pack;
$l->unpack;

ok(1);
