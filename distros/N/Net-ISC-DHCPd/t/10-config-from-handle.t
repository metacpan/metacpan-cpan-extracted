#!perl

use warnings;
use strict;
use lib './lib';
use Test::More;

plan tests => 2;

use_ok("Net::ISC::DHCPd::Config");

my $config = Net::ISC::DHCPd::Config->new(fh => \*DATA, file => "./t/data/dhcpd.conf");

is($config->parse, 10, "all config lines parsed");

__DATA__
subnet 10.0.0.96 netmask 255.255.255.224
{
    option domain-name "isc.org";
    option domain-name-servers ns1.isc.org, ns2.isc.org;
    option routers 10.0.0.97;

    pool {
        range 10.0.0.98 10.0.0.103;
    }
}
