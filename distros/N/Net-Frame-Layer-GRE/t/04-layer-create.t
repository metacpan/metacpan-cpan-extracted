use Test;
BEGIN { plan(tests => 1) }

use Net::Frame::Layer::GRE qw(:consts);

my $l = Net::Frame::Layer::GRE->new;
$l->pack;
$l->unpack;

ok(1);
