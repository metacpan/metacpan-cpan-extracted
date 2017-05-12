use Test;
BEGIN { plan(tests => 1) }

use Net::Frame::Layer::LLC qw(:consts);

my $l = Net::Frame::Layer::LLC->new;
$l->pack;
$l->unpack;

ok(1);
