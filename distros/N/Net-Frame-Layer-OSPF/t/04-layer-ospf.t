use Test;
BEGIN { plan(tests => 1) }

use Net::Frame::Layer::OSPF qw(:consts);

my $l = Net::Frame::Layer::OSPF->new;
$l->pack;
$l->unpack;

ok(1);
