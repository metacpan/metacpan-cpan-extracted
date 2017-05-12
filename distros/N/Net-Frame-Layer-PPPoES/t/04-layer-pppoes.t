use Test;
BEGIN { plan(tests => 1) }

use Net::Frame::Layer::PPPoES qw(:consts);

my $l = Net::Frame::Layer::PPPoES->new;
$l->pack;
$l->unpack;

ok(1);
