use Net::ISC::DHCPd::Config;
use Test::More;
use warnings;

my $config = Net::ISC::DHCPd::Config->new(fh => \*DATA);
is($config->parse, 41, 'Parsed xx lines?');
is($config->failoverpeers->[0]->name, 'failover', 'primary failoverpeer = failover');
is($config->failoverpeers->[1]->name, 'failover-partner', 'secondary');
is($config->failoverpeers->[2]->name, 'one-line', 'secondary');
is($config->failoverpeers->[1]->type, 'secondary', 'is type for second failover secondary?');
is($config->failoverpeers->[2]->type, undef, 'is type for third failover undef?');
is($config->failoverpeers->[0]->peer_port, 520, 'is peer port for first failver 520?');
is($config->subnets->[0]->pools->[0]->keyvalues->[0]->name, 'failover', 'does the failover peer option work');
done_testing();

__DATA__
failover peer "failover" {
    primary;
    address dhcp-primary.example.com;
    port 519;
    peer address dhcp-secondary.example.com;
    peer port 520;
    max-response-delay 60;
    max-unacked-updates 10;
    mclt 3600;
    split 128;
    load balance max seconds 3;
}

# secondary isn't allowed to have mclt or split.  The parameters should
# otherwise match the primary.
failover peer "failover-partner" {
    secondary;
    address dhcp-secondary.example.com;
    port 520;
    peer address dhcp-primary.example.com;
    peer port 519;
    max‐response‐delay 60;
    max‐unacked‐updates 10;
    load balance max seconds 3;
}

failover peer one-line {
    address dhcp-secondary.example.com; port 520; peer address dhcp-primary.example.com; peer port 519; max‐response‐delay 60; max‐unacked‐updates 10; load balance max seconds 3;
}

subnet 10.100.100.0 netmask 255.255.255.0 {

   option domain-name-servers 10.0.0.53;
   option routers 10.100.100.1;
   pool {
       failover peer "failover-partner";
       range 10.100.100.20 10.100.100.254;
   }
}


