use Test;
BEGIN { plan(tests => 1) }

use Net::Frame::Layer::PPPLCP qw(:consts);

my $l = Net::Frame::Layer::PPPLCP->new;
$l->pack;
$l->unpack;

ok(1);
