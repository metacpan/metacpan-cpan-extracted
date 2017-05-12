use Test;
BEGIN { plan(tests => 1) }

use Net::Frame::Layer::OSPF::Hello;

my $l = Net::Frame::Layer::OSPF::Hello->new;
$l->pack;
$l->unpack;

ok(1);
