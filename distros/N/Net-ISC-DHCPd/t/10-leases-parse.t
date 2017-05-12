#!perl

use warnings;
use strict;
use lib './lib';
use Benchmark;
use Time::Local;
use Test::More;

my $count  = $ENV{'COUNT'} || 1;
my $leases = "./t/data/dhcpd.leases";
my $lines  = 104;

plan tests => 1 + 12 * $count;

use_ok("Net::ISC::DHCPd::Leases");

my $time = timeit($count, sub {
    my $leases = Net::ISC::DHCPd::Leases->new(file => $leases);
    my $lease;

    is(ref $leases, "Net::ISC::DHCPd::Leases", "leases object constructed");
    is($leases->parse, $lines, "all leases lines parsed");
    is(scalar(@_=$leases->leases), 10, "got leases");

    $lease = $leases->leases->[0];

    is($lease->starts, timelocal(32, 42, 19, 13, 6, 2008), "lease->0 starts");
    is($lease->ends, timelocal(32, 42, 19, 14, 6, 2008), "lease->0 ends");
    is($lease->ip_address, '10.19.83.199', 'lease->0 ip_address');
    is($lease->state, "free", "lease->0 binding");
    is($lease->hardware_address, "00:15:58:2f:83:bc", "lease->0 hw_ethernet");
    is($lease->client_hostname, undef, "lease->0 hostname");
    is($lease->circuit_id, undef, "lease->0 circuit id");
    is($lease->remote_id, undef, "lease->0 remote id");

    is($leases->find_leases({ hardware_address => '00:12:f0:50:06:48' }), 1, 'found lease with hardware_address=00:12:f0:50:06:48');
});

diag(($lines * $count) .": " .timestr($time));

