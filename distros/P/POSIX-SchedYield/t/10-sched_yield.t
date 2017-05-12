#!/perl

use strict;
use warnings;
use Test::More tests => 4;

BEGIN {
    use_ok ('POSIX::SchedYield');
}

can_ok('POSIX::SchedYield','sched_yield');
is(POSIX::SchedYield::sched_yield(),1,"Returned success on execution");

my ($strace,$binary);
if ($^O =~ m/linux/) {
    $binary = find_in_path("strace");
# For FreeBSD test whether /proc is mounted
} elsif ($^O =~ m/freebsd/ && -e "/proc/$$") {
    $binary = find_in_path("strace")
        || find_in_path("truss");
}

SKIP: {
    skip "cannot trace on this platform or trace binary not found ",1 if (!defined $binary);
    $strace = "$binary perl examples/yield.pl 2>&1";
    like (`$strace`,qr/sched_yield/,"strace reports system call executed");
}

sub find_in_path {
    my $binary = shift;
    for my $path(split(/:/,$ENV{PATH})) {
        my $examine = $path."/".$binary;
        return $examine if -e $examine;
    }
    return;
}
