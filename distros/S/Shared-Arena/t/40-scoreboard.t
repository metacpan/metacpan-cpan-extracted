#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Time::HiRes ();
use Shared::Arena ();

# ONE ROW PER WORKER, PUBLISHED LIVE.
#
# The inverse of every other table here: each worker owns one row and is its
# only writer, so an update takes no lock, and a reader sees the whole board in
# one pass. Apache's scoreboard for a fork pool.
#
# What one process cannot show, and the fork blocks below do:
#   * many workers each get their OWN row - the board partitions,
#   * a reader gets a COHERENT snapshot of a row being updated (never a mix of
#     the count from before and the status from after),
#   * a dead worker's row reads alive => 0, and is then RECLAIMED by a new
#     worker rather than leaked.

plan skip_all => 'no atomics in this build' unless Shared::Arena::have_atomics();

my $arena = Shared::Arena->create(size => 4 * 1024 * 1024);

# Every child goes through this ONE fork call site, and it returns the pid so a
# caller can read the board while the child is still alive and reap it later.
# One site keeps xt/win32-fork.t happy (the forks a whole file has must each be
# skippable on a threaded perl); the SKIP blocks below are where MSWin32 stops.
sub spawn {
    my $code = shift;
    my $pid = fork;
    die "fork: $!" unless defined $pid;
    unless ($pid) { $code->(); exit 0 }
    return $pid;
}

# ---- single process: the basics --------------------------------------------

{
    my $sb = $arena->scoreboard('basic', fields => ['inflight', 'served']);
    is_deeply([$sb->fields], ['inflight', 'served'], 'the schema is what we named');
    ok(defined $sb->take, 'claimed a row');
    is($sb->mine, 0, 'the first row');

    $sb->update(inflight => 3, served => 10, status => 'GET /x');
    $sb->incr(served => 5);
    $sb->incr(inflight => -1);

    my @rows = $sb->all;
    is(scalar @rows, 1, 'one live row');
    is($rows[0]{inflight}, 2, 'a gauge set then decremented');
    is($rows[0]{served}, 15, 'a gauge set then added to');
    is($rows[0]{status}, 'GET /x', 'the status line');
    is($rows[0]{pid}, $$, 'the row is ours');
    ok($rows[0]{alive}, 'and we are alive');

    eval { $sb->update(nope => 1); 1 };
    like($@, qr/no field 'nope'/, 'a typo in a field name is a croak, not a silent no-op');
}

# ---- the shape is the board's, not the caller's ----------------------------

{
    $arena->scoreboard('shape', fields => ['a', 'b']);
    my $again = eval { $arena->scoreboard('shape', fields => ['a', 'c']) };
    ok(!$again, 'a caller naming different fields is refused');
    like($@, qr/different type or size|already carved/,
         '...as a shape disagreement');
    # But inheriting the schema is fine.
    my $ok = eval { $arena->scoreboard('shape') };
    ok($ok, 'a caller naming no fields inherits the schema');
    is_deeply([$ok->fields], ['a', 'b'], '...and gets the real columns');
}

# ---- each worker gets its own row ------------------------------------------

SKIP: {
    skip 'fork is POSIX-only here', 3 if $^O eq 'MSWin32';

    my $KIDS = 5;
    my $sb = $arena->scoreboard('pool', fields => ['served'], slots => 16);
    pipe(my $rd, my $wr) or die "pipe: $!";

    my @pid = map {
        my $k = $_;
        spawn(sub {
            close $rd;
            my $board = $arena->scoreboard('pool');
            my $row = $board->take;
            $board->update(served => $k * 100, status => "worker $k");
            syswrite($wr, "$$ $row\n");
            select undef, undef, undef, 0.3;   # stay alive so the parent reads us
        });
    } 1 .. $KIDS;
    close $wr;

    my %row_of;
    while (my $line = <$rd>) {
        chomp $line;
        my ($p, $r) = split ' ', $line;
        $row_of{$p} = $r;
    }

    # Read the board while the children are still alive.
    select undef, undef, undef, 0.1;
    my @rows = $sb->all;
    my %by_pid = map { $_->{pid} => $_ } @rows;

    waitpid($_, 0) for @pid;

    is(scalar keys %row_of, $KIDS, "all $KIDS workers claimed a row");
    my %seen_row; $seen_row{$_}++ for values %row_of;
    is_deeply([grep { $seen_row{$_} > 1 } keys %seen_row], [],
              'and no two workers got the same row');

    # Each worker's gauge is its own, read straight off the board.
    my $consistent = 1;
    for my $p (keys %row_of) {
        $consistent = 0 unless $by_pid{$p} && $by_pid{$p}{served} % 100 == 0;
    }
    ok($consistent, "each worker's own gauge is visible on the board");
}

# ---- a coherent snapshot under concurrent updates --------------------------
#
# The classic seqlock torture: the writer flips a GAUGE and a WIDE status line
# in lockstep - kind 1 goes with a 60-char 'A' line, kind 2 with a 'B' line -
# and a reader checks they agree. A torn read is one where the gauge says one
# kind and the status is the other, or half of each. The 60-byte status copy is
# a wide window on purpose: two lock-step integers are too narrow to catch a
# missing recheck on a fast box (an earlier version of this test passed even
# with the seqlock recheck removed), and the whole point is to catch exactly
# that.

SKIP: {
    skip 'fork is POSIX-only here', 2 if $^O eq 'MSWin32';

    my $sb = $arena->scoreboard('coherent', fields => ['kind'], slots => 4);
    my $A = 'A' x 60;
    my $B = 'B' x 60;

    my $pid = spawn(sub {
        my $b = $arena->scoreboard('coherent');
        $b->take;
        my $end = Time::HiRes::time() + 0.6;
        my $k = 1;
        while (Time::HiRes::time() < $end) {
            for (1 .. 200) {
                $k = $k == 1 ? 2 : 1;
                $b->update(kind => $k, status => ($k == 1 ? $A : $B));
            }
        }
    });

    my $torn = 0;
    my $reads = 0;
    my $end = Time::HiRes::time() + 0.4;
    while (Time::HiRes::time() < $end) {
        for my $r ($sb->all) {
            next unless $r->{kind};
            $reads++;
            my $want = $r->{kind} == 1 ? $A : $B;
            $torn++ if $r->{status} ne $want;
        }
    }
    waitpid($pid, 0);
    cmp_ok($reads, '>', 1000, 'the reader really read the row while it was live');
    is($torn, 0, 'the gauge and the wide status never disagreed: no torn snapshot');
}

# ---- a dead worker's row: alive => 0, then reclaimed -----------------------

SKIP: {
    skip 'fork is POSIX-only here', 3 if $^O eq 'MSWin32';

    # A one-row board, so reclaim is forced: the second worker can only get a
    # row by taking over the first, dead one.
    my $sb = $arena->scoreboard('reclaim', fields => ['served'], slots => 1);

    my $pid = spawn(sub {
        my $b = $arena->scoreboard('reclaim');
        my $r = $b->take;
        $b->update(served => 42, status => 'the first worker');
        exit(defined $r ? 0 : 9);
    });
    waitpid($pid, 0);
    is($? >> 8, 0, 'the first worker claimed the only row');

    # Its row is still on the board, but its owner is gone.
    my ($row) = $sb->all;
    ok($row, 'the dead worker\'s row is still there');
    is($row->{alive}, 0, '...and reads as not alive, not as current');

    # A new worker reclaims the only row rather than failing.
    my $pid2 = spawn(sub {
        my $b = $arena->scoreboard('reclaim');
        my $r = $b->take;
        $b->update(served => 7, status => 'the successor');
        exit(defined $r ? 0 : 9);
    });
    waitpid($pid2, 0);
    is($? >> 8, 0, 'a new worker reclaimed the dead one\'s row');
}

done_testing;
