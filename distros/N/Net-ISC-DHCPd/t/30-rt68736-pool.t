use Net::ISC::DHCPd::Config;
use Test::More;
use warnings;
use strict;

my $config = Net::ISC::DHCPd::Config->new(fh => \*DATA);
is($config->parse, 19, 'Parsed 19 lines?');
is($config->subnets->[0]->options->[0]->name, 'routers', 'is subnet options 0 name == routers?');
is(scalar(@{$config->subnets->[0]->pools}), 2, 'Is the number of pools == 2?');
is($config->subnets->[0]->pools->[0]->ranges->[0]->lower, '10.0.0.200/32', 'lower pool 0 range');
is($config->subnets->[0]->pools->[0]->keyvalues->[1]->name, 'allow', 'allow unknown-clients');
done_testing();


__DATA__
subnet 10.0.0.0 netmask 255.255.255.0 {
    option routers 10.0.0.254;

    # Unknown clients get this pool.
    pool {
        option domain-name-servers bogus.example.com;
        max-lease-time 300;
        range 10.0.0.200 10.0.0.253;
        allow unknown-clients;
    }

    # Known clients get this pool.
    pool {
        option domain-name-servers ns1.example.com, ns2.example.com;
        max-lease-time 28800;
        range 10.0.0.5 10.0.0.199;
        deny unknown-clients;
    }
}
