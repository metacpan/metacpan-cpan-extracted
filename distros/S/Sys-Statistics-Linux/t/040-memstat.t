use strict;
use warnings;
use Test::More;
use Sys::Statistics::Linux;

if (!-r '/proc/meminfo') {
    plan skip_all => "it seems that your system doesn't provide memory statistics";
    exit(0);
}

my @memstats = qw(
    memused
    memfree
    memusedper
    memtotal
    buffers
    cached
    realfree
    realfreeper
    swapused
    swapfree
    swapusedper
    swaptotal
    swapcached
    active
    inactive
);

my @memstats26  = qw(committed_as);
my @memstats269 = qw(commitlimit);

open my $fh, '<', '/proc/sys/kernel/osrelease' or die $!;
my @rls = split /\./, <$fh>;
close $fh;

my $sys = Sys::Statistics::Linux->new();
$sys->set(memstats => 1);
my $stats = $sys->get;

if ($rls[0] < 6) {
    plan tests => 15;
} else {
    push @memstats, $_ for @memstats26;
    if ($rls[1] < 9) {
        plan tests => 16;
    } else {
        plan tests => 17;
        push @memstats, $_ for @memstats269;
    }
}

ok(defined $stats->memstats->{$_}, "checking memstats $_") for @memstats;
