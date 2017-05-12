use Test;
BEGIN { plan(tests => 1) }

use Net::Frame::Layer::LOOP qw(:consts);

my $l = Net::Frame::Layer::LOOP->new;
$l->pack;
$l->unpack;

ok(1);
