use strict;
use warnings;
use Test::More;
use Sys::Statistics::Linux;

for my $f ("/proc/$$/stat","/proc/$$/statm","/proc/$$/status","/proc/$$/cmdline","/proc/$$/wchan") {
    if (!-r $f) {
        plan skip_all => "$f is not readable";
        exit(0);
    }
}

my @processes = qw(
    ppid
    nlwp
    owner
    pgrp
    state
    session
    ttynr
    minflt
    cminflt
    mayflt
    cmayflt
    stime
    utime
    ttime
    cstime
    cutime
    prior
    nice
    sttime
    actime
    vsize
    nswap
    cnswap
    cpu
    size
    resident
    share
    trs
    drs
    lrs
    dtp
    cmd
    cmdline
    wchan
    fd
);

my $sys = Sys::Statistics::Linux->new();
$sys->set(processes => 1);
sleep(1);
my $stats = $sys->get;

if (!scalar keys %{$stats->processes}) {
    plan skip_all => "processlist is empty";
    exit(0);
}

plan tests => 35;

for my $pid (keys %{$stats->processes}) {
   ok(defined $stats->processes->{$pid}->{$_}, "checking processes $_") for @processes;
   last; # we check only one process, that should be enough
}
