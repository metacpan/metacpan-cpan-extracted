use Net::ISC::DHCPd::Config;
use Test::More;
use warnings;

# without this it seeks back to beginning of the perl script
my $data_pos = tell DATA;
my $output = do { local($/); <DATA> };
seek DATA, $data_pos, 0;

my $config = Net::ISC::DHCPd::Config->new(fh => \*DATA);
is($config->parse, 31, 'Parsed 31 lines?');
is($config->generate, $output, 'Does generated config match input?');
is($config->subnet6s->[0]->address, '3ffe:501:ffff:100:0:0:0:0/64', 'subnet6s address match input?');
is($config->subnet6s->[0]->range6s->[0]->lower->short, '3ffe:501:ffff:100::10', 'range6s address match input?');
is($config->subnet6s->[0]->range6s->[1]->temporary, 1, 'range6s 2 temporary?');
done_testing();

__DATA__
default-lease-time 2592000;
preferred-lifetime 604800;
option dhcp-renewal-time 3600;
option dhcp-rebinding-time 7200;
option dhcp6.name-servers 3ffe:501:ffff:100:200:ff:fe00:4f4e;
option dhcp6.domain-search "test.example.com","example.com";
option dhcp6.info-refresh-time 21600;
# The path of the lease file
dhcpv6-lease-file-name "/usr/local/var/db/dhcpd6.leases";
host myclient {
    # The entry is looked up by this
    host-identifier option dhcp6.client-id 00:01:00:01:00:04:93:e0:00:00:00:00:a2:a2;
    fixed-address6 3ffe:501:ffff:100::1234;
    # A fixed prefix
    fixed-prefix6 3ffe:501:ffff:101::/64;
    # Override of the global definitions,
    option dhcp6.name-servers 3ffe:501:ffff:100:200:ff:fe00:4f4f;
}
# Enable RFC 5007 support (same than for DHCPv4)
allow leasequery;
option dhcp6.info-refresh-time 21600;
subnet6 3ffe:501:ffff:100::/64 {
    # Two addresses available to clients
    # (the third client should get NoAddrsAvail)
    range6 3ffe:501:ffff:100::10 3ffe:501:ffff:100::11;
    # Use the whole /64 prefix for temporary addresses
    # (i.e., direct application of RFC 4941)
    range6 3ffe:501:ffff:100:: temporary;
    # Some /64 prefixes available for Prefix Delegation (RFC 3633)
    prefix6 3ffe:501:ffff:100:: 3ffe:501:ffff:111:: /64;
}
