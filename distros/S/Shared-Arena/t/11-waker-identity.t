#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp ();
use Shared::Arena ();

# A DESCRIPTOR NUMBER IS PROCESS-LOCAL STATE.
#
# The waker table holds `rfd` and `wfd` as plain ints in shared memory. That is
# the same mistake as storing a pointer there, and it hides in exactly the same
# way: fork children inherit the descriptors along with the table, so the
# numbers agree and every test that only forks passes.
#
# They agree for nobody else. A process that attached to a named region
# inherited nothing, and its fd 4 is its own fd 4 - a log, a socket, the
# harness's own output. Publishing used to write a wakeup byte straight into it.
#
# THE TEST REPRODUCES THAT WITHOUT NEEDING AN UNRELATED PROCESS: a fork child
# closes every inherited descriptor above stdio, which is precisely the state an
# attacher is in, and then opens ordinary files so they land on the numbers the
# pipes used to occupy. If publishing still trusts the table, one of those files
# gets a \001 in it.
#
# The fix is that the table records what the pipes ARE - the device and inode of
# slot 0's read end - and a process checks once, with one fstat, whether the
# descriptors are the ones it holds. A process that fails does not poke and does
# not claim a slot; it polls, which is what the POD promises it anyway.

plan skip_all => 'no atomics in this build' unless Shared::Arena::have_atomics();
plan skip_all => 'wakeups are POSIX-only' if $^O eq 'MSWin32';

require POSIX;

my $dir = File::Temp::tempdir(CLEANUP => 1);
my $victim = "$dir/victim";

my $arena = Shared::Arena->create(size => 512 * 1024);
my $ring  = $arena->ring('r', slots => 64, slot_size => 128);
ok($arena->wakers(4), 'made the wakers before any fork');

my $idx = $arena->waker;
cmp_ok($idx, '>=', 0, 'the parent claimed a waker');
my $parent_rfd = $arena->waker_fd;
cmp_ok($parent_rfd, ">=", 0, "...and has a descriptor to select on");

my $pid = fork;
die "fork: $!" unless defined $pid;

if (!$pid) {
    # Exactly the state a process that attached by name is in: the table is
    # readable, the descriptors it names are not ours.
    POSIX::close($_) for 3 .. 30;

    # Stand ordinary files where the pipes were. The first free descriptor is
    # 3, so these occupy the numbers the wakers used.
    my @fh;
    for (1 .. 6) {
        open my $fh, '>', $victim or exit 9;
        push @fh, $fh;
    }

    # NOT OPTIONAL. If these files did not land on the numbers the pipes used,
    # the assertion below is of nothing at all and would pass with the bug in
    # place. The parent's read end is the one number we know, so require it.
    my %took = map { fileno($_) => 1 } @fh;
    exit 7 unless $took{$parent_rfd};

    # A process with no pipes of its own must say so rather than handing back
    # somebody else's number.
    exit 8 unless $arena->waker_fd == -1;

    # And this must not write into any of them.
    $ring->publish('topic', 'a record from a process with no pipes');
    exit 0;
}

waitpid($pid, 0);
my $status = $? >> 8;

isnt($status, 7, 'the victim files landed on the descriptors the pipes used');
isnt($status, 9, 'the child could open its files');
isnt($status, 8, 'a process without the pipes reports no descriptor');
is($status, 0, 'the child published without error');

ok(-e $victim, 'the file that stood where a pipe was exists');
is(-s $victim, 0, 'and NOTHING was written into it');

# The feature still works: the record the child published is really there.
my $cur = $ring->cursor(from_start => 1);
my @got = $cur->drain;
is(scalar @got, 1, 'the record was published all the same');

done_testing;
