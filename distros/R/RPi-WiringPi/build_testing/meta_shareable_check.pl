#!/usr/bin/env perl

# No-XS functional gate for the IPC::Shareable (tie-a-scalar) backend in
# RPi::WiringPi::Meta. Blesses a bare object into the Meta mixin (no WiringPi
# XS) and exercises the full meta_* surface: lock/fetch/store, set/get/delete,
# erase(0/1), key, key_check(present/absent), nested-mutation detachment, a
# cross-process fork, and the single-segment (no fan-out) guarantee.
#
# Run:  perl -Ilib build_testing/meta_shareable_check.pl
#
# With --size, additionally runs the V10 segment-size checks: store a realistic
# worst-case blob (~40 objects + ~40 pins + a few KB of user storage), confirm
# it round-trips in a SINGLE segment with wide headroom, report the as-stored
# (double-serialized) byte size vs. our raw JSON length, then deliberately
# overflow the segment and confirm IPC::Shareable croaks cleanly while leaving
# the existing segment contents intact.
#
# Run:  perl -Ilib build_testing/meta_shareable_check.pl --size
#
# The segment is intentionally left intact (destroy => 0). Re-running attaches
# to the same segment and reports the persisted __runs counter.

use strict;
use warnings;

use POSIX ();
use Test::More;

use lib 'lib';
use RPi::WiringPi::Meta;

my $KEY    = 'rpit';
my $ABSENT = 'blah';

# --size adds the V10 segment-size headroom + overflow/cap checks.
my $RUN_SIZE = grep { $_ eq '--size' } @ARGV;

my $obj = bless { shm_key => $KEY }, 'RPi::WiringPi::Meta';

# Persistence across actual reruns (informational): read any marker left by a
# previous invocation before we reset the segment.
{
    my $runs = $obj->meta_fetch->{storage}{__runs} // 0;
    diag "segment persisted from a prior run: __runs = $runs" if $runs;
}

# Reset to a known-empty blob so the rest of the assertions are deterministic
# regardless of what a prior run left behind.
$obj->meta_lock;
$obj->meta_store({});
$obj->meta_unlock;

# --- key + key_check ---------------------------------------------------------
is($obj->meta_key, 1473559184, "meta_key returns the CRC32-derived int for '$KEY'");
is(RPi::WiringPi::Meta->meta_key_check($KEY), 1, "meta_key_check('$KEY') sees the live segment");
is(RPi::WiringPi::Meta->meta_key_check($ABSENT), 0, "meta_key_check('$ABSENT') reports absent");

# --- lock / fetch / store round-trip ----------------------------------------
$obj->meta_lock;
my $m = $obj->meta_fetch;
is_deeply($m, {}, 'fetch on a freshly-reset segment is empty');
$m->{objects}{'uuid-a'} = { proc => $$, label => 'p' };
$m->{object_count} = 1;
$obj->meta_store($m);
$obj->meta_unlock;
is_deeply(
    $obj->meta_fetch->{objects}{'uuid-a'},
    { proc => $$, label => 'p' },
    'lock/fetch/store round-trips a nested value'
);

# --- nested-mutation detachment: a fetched copy is detached until stored -----
$obj->meta_lock;
my $a = $obj->meta_fetch;
$a->{pins}{17} = {
    alt     => 0,
    state   => 1,
    mode    => 1,
    comment => 'c',
    users   => { 'uuid-a' => 1 },
};
my $b = $obj->meta_fetch;       # second fetch, BEFORE the store
ok(! exists $b->{pins}, 'mutating a fetched copy does not touch the segment (detached)');
$obj->meta_store($a);
$obj->meta_unlock;
ok(exists $obj->meta_fetch->{pins}{17}, 'nested mutation persists only after meta_store');

# --- single segment for the whole nested blob (no fan-out) -------------------
my $segs = IPC::Shareable::global_register();
is(scalar keys %$segs, 1, 'exactly one shm segment backs the whole nested blob (no fan-out)');

# --- meta_set / meta_get / meta_delete (user storage slots) -----------------
my %data = (a => 1, b => [1, 2, 3]);
$obj->meta_set('mydata', \%data);
is_deeply($obj->meta_get('mydata'), \%data, 'meta_set then meta_get round-trips user data');
$obj->meta_delete('mydata');
is($obj->meta_get('mydata'), undef, 'meta_delete removes the storage slot');

# --- meta_erase(0): keep user storage, wipe software keys --------------------
$obj->meta_set('keepme', { x => 1 });
$obj->meta_erase(0);
{
    my $after = $obj->meta_fetch;
    is_deeply($after->{storage}{keepme}, { x => 1 }, 'erase(0) preserves user storage');
    ok(! exists $after->{objects}, 'erase(0) wipes software keys (objects)');
    ok(! exists $after->{pins},    'erase(0) wipes software keys (pins)');
}

# --- meta_erase(1): wipe everything -----------------------------------------
$obj->meta_erase(1);
is_deeply($obj->meta_fetch, {}, 'erase(1) wipes the entire blob');

# --- cross-process fork: child sees parent write; parent sees child write
#     after the child has exited (segment survives process death) ------------
$obj->meta_lock;
my $pm = $obj->meta_fetch;
$pm->{storage}{from_parent} = 'hello-child';
$obj->meta_store($pm);
$obj->meta_unlock;

my $pid = fork;
defined $pid or die "fork failed: $!";

if ($pid == 0) {
    # child process
    $obj->meta_lock;
    my $cm  = $obj->meta_fetch;
    my $saw = $cm->{storage}{from_parent} // '(nothing)';
    $cm->{storage}{from_child} = "child-saw:$saw";
    $obj->meta_store($cm);
    $obj->meta_unlock;
    POSIX::_exit(0);                 # skip parent END blocks (no stray TAP)
}

waitpid $pid, 0;
is(
    $obj->meta_fetch->{storage}{from_child},
    'child-saw:hello-child',
    'fork: child read parent write, parent read child write after child exit'
);

# --- V10: segment-size headroom + overflow/cap behavior (--size) ------------
if ($RUN_SIZE) {
    # (a) Realistic worst-case blob: ~40 live objects + ~40 registered pins +
    # several KB of user storage. Confirm it round-trips inside a SINGLE
    # segment with wide headroom, and report the as-stored (double-serialized)
    # byte size against our raw JSON length to quantify the escaping inflation.
    my %big;

    for my $i (1 .. 40) {
        my $uuid = sprintf 'uuid-%032d', $i;
        $big{objects}{$uuid} = { proc => 100000 + $i, label => "object-label-$i" };
    }
    $big{object_count} = 40;

    for my $pin (0 .. 39) {
        $big{pins}{$pin} = {
            alt     => 0,
            state   => 1,
            mode    => 1,
            comment => "pin $pin in use by an application module",
            users   => { sprintf('uuid-%032d', 1) => 1 },
        };
    }
    $big{pwm} = { in_use => 1, users => { sprintf('uuid-%032d', 1) => 1 } };

    for my $slot (1 .. 8) {
        $big{storage}{"user_slot_$slot"} =
            { map { ("field_$_" => "value-$_-" . ('y' x 20)) } 1 .. 12 };
    }

    $obj->meta_lock;
    $obj->meta_store(\%big);
    $obj->meta_unlock;

    my $cap       = $obj->meta->seg->size;
    my $raw_bytes = length ${ $obj->{meta_scalar} };
    my $as_stored = length $obj->meta->seg->data;

    diag sprintf(
        'realistic blob: raw JSON %d B, as-stored %d B (+%.1f%% double-serialize inflation), %.1f%% of %d B cap',
        $raw_bytes, $as_stored, 100 * ($as_stored / $raw_bytes - 1),
        100 * $as_stored / $cap, $cap
    );

    cmp_ok($as_stored, '<', $cap / 2,
        'realistic worst-case blob fits with wide margin (< half the segment cap)');

    my $segs = IPC::Shareable::global_register();
    is(scalar keys %$segs, 1,
        'the whole realistic blob still lives in exactly one segment (no fan-out)');

    is_deeply($obj->meta_fetch, \%big,
        'realistic worst-case blob round-trips intact through the segment');

    # (b) Deliberate overflow: a payload larger than the segment must croak
    # cleanly and leave the existing segment contents intact (no silent
    # truncation/corruption). Run the failing store in a CHILD so its leaked
    # IPC::Shareable lock state dies with it and can't deadlock this process.
    my $oversized = 'x' x ($cap + 16384);

    my $opid = fork;
    defined $opid or die "fork failed: $!";

    if ($opid == 0) {
        my $kid = bless { shm_key => $KEY }, 'RPi::WiringPi::Meta';
        my $ok  = eval {
            $kid->meta_lock;
            $kid->meta_store({ storage => { blob => $oversized } });
            $kid->meta_unlock;
            1;
        };
        my $clean = (! $ok && $@ =~ /exceeds shared segment size/) ? 1 : 0;
        POSIX::_exit($clean ? 7 : 8);    # skip parent END blocks (no stray TAP)
    }

    waitpid $opid, 0;
    is($? >> 8, 7,
        'oversized store croaks cleanly ("exceeds shared segment size")');

    is_deeply($obj->meta_fetch, \%big,
        'segment left intact after the failed oversized store (no truncation/corruption)');

    # Reset to a clean blob so the persistence marker below starts fresh.
    $obj->meta_lock;
    $obj->meta_store({});
    $obj->meta_unlock;
}

# Leave a persistence marker (increment a run counter) and DO NOT destroy the
# segment, so a subsequent run attaches to the same segment and sees this.
$obj->meta_lock;
my $final = $obj->meta_fetch;
$final->{storage}{__runs} = ($final->{storage}{__runs} // 0) + 1;
$obj->meta_store($final);
$obj->meta_unlock;
pass('segment left intact (destroy => 0); rerun to watch __runs increment');

done_testing();
