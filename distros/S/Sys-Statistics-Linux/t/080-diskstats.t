use strict;
use warnings;
use Test::More;
use Sys::Statistics::Linux;

my @diskstats = qw(
    major
    minor
    rdreq
    rdbyt
    wrtreq
    wrtbyt
    ttreq
    ttbyt
);

my $sys = Sys::Statistics::Linux->new();

if (!-r '/proc/diskstats' || !-r '/proc/partitions') {
    plan skip_all => "your system doesn't provide disk statistics - /proc/diskstats and /proc/partitions is not readable";
    exit(0);
}

# I try to set this option in an eval box first because
# it could be that this test fails if the linux kernel
# version is <= 2.4 and if the kernel is not compiled with
# CONFIG_BLK_STATS=y
eval { $sys->set(diskstats => 1) };

if ($@) {
    if ($@ =~ /CONFIG_BLK_STATS/) {
        plan skip_all => "your system seems not to be compiled with CONFIG_BLK_STATS=y! diskstats will not run on your system!";
    } else {
        plan tests => 1;
        fail("$@");
    }
} else {
    plan tests => 8;
    $sys->set(diskstats => 1);
    sleep(1);
    my $stats = $sys->get;

    for my $dev (keys %{$stats->diskstats}) {
        ok(defined $stats->diskstats->{$dev}->{$_}, "checking diskstats $_") for @diskstats;
        last; # we check only one device, that should be enough
    }
}
