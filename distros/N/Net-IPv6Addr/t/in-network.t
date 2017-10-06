use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Test::More;
use Net::IPv6Addr;
my $addr = 'fd00::54:20c:29fe:fe14:ab4b';
my $x = new Net::IPv6Addr($addr);
my $in;
eval {
    $in = $x->in_network("aa:bb:cc:dd::/64");
};
ok (! $@, "no error with address $addr");
ok (! $in, "not in network OK");
$in = $x->in_network ($addr, 64);
ok ($in, "network is in itself for 64 bits");
$in = $x->in_network ($addr, 68);
ok ($in, "network is in itself for 68 bits");
eval {
$in = $x->in_network ($addr, 68888);
};
ok ($@, "Too-big network gives error");

my $abcd = 'abcd:' x 7 . 'abcd';
my $y = Net::IPv6Addr->new ($abcd);
my $obj = $y->in_network_of_size (64);
my @ints = $obj->to_intarray ();
my $h = hex ('abcd');
my $trunk = [$h, $h, $h, $h, 0, 0, 0, 0];
is_deeply (\@ints, $trunk, "Truncated to sixty-four bits");
my $obj2 = $y->in_network_of_size (68);
my @ints2 = $obj2->to_intarray ();
my $trunk2 = [$h, $h, $h, $h, $h & 0xF000, 0, 0, 0];
is_deeply (\@ints2, $trunk2, "Truncated to sixty-eight bits");
done_testing ();
