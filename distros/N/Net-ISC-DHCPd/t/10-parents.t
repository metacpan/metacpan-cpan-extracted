#!perl

use warnings;
use strict;
use lib q(lib);
use Net::ISC::DHCPd::Config;
use Test::More;

my $config = Net::ISC::DHCPd::Config->new(fh => \*DATA);
$config->parse;

is($config->keyvalues->[0]->parent, $config, 'is the parent correct for keyvalue0');
is($config->subnets->[0]->pools->[0]->root, $config, 'is the root correct for subnet0/pool0');
is($config->subnets->[0]->pools->[0]->ranges->[0]->parent->parent, $config->subnets->[0], 'is the parent correct for subnet0/pool0/range0');
done_testing();

__DATA__
ddns-update-style none;
subnet 10.0.0.96 netmask 255.255.255.224 {
    filename pxefoo.0;
    option routers 10.0.0.97;
    pool {
        range 10.0.0.126 10.0.0.116;
    }
}
