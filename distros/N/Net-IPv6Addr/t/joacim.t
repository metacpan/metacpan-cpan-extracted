use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Test::More;
use Net::IPv6Addr;
my $addr = 'fd00::54:20c:29fe:fe14:ab4b';
my $x = new Net::IPv6Addr($addr);
eval {
    $x->in_network("aa:bb:cc:dd::/64");
};
ok (! $@, "no error with address $addr");
done_testing ();
