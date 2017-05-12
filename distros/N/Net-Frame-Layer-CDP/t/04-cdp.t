use Test;
BEGIN { plan(tests => 1) }

use Net::Frame::Layer::CDP qw(:consts);

my $l = Net::Frame::Layer::CDP->new;
$l->pack;
$l->unpack;

print $l->print."\n";

my $encap = $l->encapsulate;
$encap ? print "[$encap]\n" : print "[none]\n";

ok(1);
