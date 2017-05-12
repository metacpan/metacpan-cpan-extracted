use Test;
BEGIN { plan(tests => 1) }

use Net::Frame::Layer::LLC::SNAP;

my $l = Net::Frame::Layer::LLC::SNAP->new;
$l->pack;
$l->unpack;

ok(1);
