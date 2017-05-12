use Test;
BEGIN { plan(tests => 1) }

use Net::Frame::Layer::UDPLite qw(:consts);

my $l = Net::Frame::Layer::UDPLite->new;
$l->pack;
print 'PACK: '.$l->print."\n";
$l->unpack;
print 'UNPACK: '.$l->print."\n";

ok(1);
