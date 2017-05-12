use Test;
BEGIN { plan(tests => 1) }

use Net::Frame::Layer::OSPF::Lls;

my $l = Net::Frame::Layer::OSPF::Lls->new;
$l->pack;
$l->unpack;

ok(1);
