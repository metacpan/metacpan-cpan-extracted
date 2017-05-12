use Test;
BEGIN { plan(tests => 1) }

use Net::Frame::Layer::OSPF::Lsa::SummaryIp;

my $l = Net::Frame::Layer::OSPF::Lsa::SummaryIp->new;
$l->pack;
$l->unpack;

ok(1);
