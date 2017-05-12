use Test;
BEGIN { plan(tests => 1) }

use Net::Frame::Layer::SinFP3 qw(:consts);

my $l = Net::Frame::Layer::SinFP3->new;
$l->pack;
$l->unpack;

ok(1);
