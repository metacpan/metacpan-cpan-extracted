use Test;
BEGIN { plan(tests => 1) }

use Net::Frame::Layer::ICMPv4::AddressMask;

my $l = Net::Frame::Layer::ICMPv4::AddressMask->new;
$l->pack;
$l->unpack;

print $l->print."\n";

my $encap = $l->encapsulate;
$encap ? print "[$encap]\n" : print "[none]\n";

ok(1);
