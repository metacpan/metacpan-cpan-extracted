use strict;
use warnings;
use Test::More;
use Sys::Statistics::Linux;

my @sockstats = qw(
   used
   tcp
   udp
   raw
);

my $sys = Sys::Statistics::Linux->new();

if (!-r '/proc/diskstats' || !-r '/proc/partitions' || !-r '/proc/net/sockstat') {
    plan skip_all => "it seems that your system doesn't provide socket statistics";
    exit(0);
}

plan tests => 5;

$sys->set(sockstats => 1);
my $stats = $sys->get;

ok(defined $stats->sockstats->{$_}, "checking sockstats $_") for @sockstats;

SKIP: { # because ipfrag is only available by kernels > 2.2
    skip "checking sockstats ipfrag", 1
        if ! defined $stats->sockstats->{ipfrag};
    ok(1, "checking sockstats ipfrag");
}
