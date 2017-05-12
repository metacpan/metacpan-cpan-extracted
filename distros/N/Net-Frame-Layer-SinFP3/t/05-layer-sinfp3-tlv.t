use Test;
BEGIN { plan(tests => 1) }

use Net::Frame::Layer::SinFP3::Tlv;

my $l = Net::Frame::Layer::SinFP3::Tlv->new;
$l->pack;
$l->unpack;

ok(1);
