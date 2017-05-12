use Test;
BEGIN { plan(tests => 1) }

use Net::Frame::Layer::STP qw(:consts);

my $l = Net::Frame::Layer::STP->new;
$l->pack;
$l->unpack;

ok(1);
