use Test;
BEGIN { plan(tests => 1) }

use Net::Frame::Layer::OSPF::DatabaseDesc;

my $l = Net::Frame::Layer::OSPF::DatabaseDesc->new;
$l->pack;
$l->unpack;

ok(1);
