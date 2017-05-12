use Test;
BEGIN { plan(tests => 1) }

use Net::Frame::Layer::8021Q qw(:consts);

my $l = Net::Frame::Layer::8021Q->new;
$l->pack;
$l->unpack;

ok(1);
