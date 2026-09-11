#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Shared::Arena ();

# OVERFLOW, AND THE ACCOUNTING THAT MAKES IT HONEST.
#
# A publisher never blocks and never fails because a reader is slow: it
# overwrites the oldest record. The contract that makes that acceptable is
# arithmetic rather than hope -
#
#     delivered + lapped == published
#
# for every cursor, always. A ring that quietly drops records is a ring whose
# users eventually build a second system to find out what it lost.

plan skip_all => 'no atomics in this build' unless Shared::Arena::have_atomics();

my $a = Shared::Arena->create(size => 1024 * 1024);

# ---- overtaken by exactly one lap ------------------------------------------
{
    my $r = $a->ring('slow', slots => 16, slot_size => 128);
    my $c = $r->cursor;

    # Fill it exactly. Nothing is lost yet: the ring holds precisely this many.
    $r->publish('n', $_) for 1 .. 16;
    my @got = $c->drain;
    is(scalar @got, 16, 'a ring filled exactly to its capacity loses nothing');
    is_deeply([map { $_->[1] } @got], [1 .. 16], 'and delivers them in order');

    my %s = $c->stats;
    is($s{lapped}, 0, 'with nothing counted as lost');
}

# ---- overtaken while not looking -------------------------------------------
{
    my $r = $a->ring('overtaken', slots => 16, slot_size => 128);
    my $c = $r->cursor;

    # Two and a half laps without draining once.
    my $sent = 40;
    $r->publish('n', $_) for 1 .. $sent;

    my @got = $c->drain;
    my %s   = $c->stats;

    cmp_ok(scalar @got, '<=', 16,
           'a cursor overtaken by 40 records into 16 slots gets at most 16');
    cmp_ok(scalar @got, '>', 0, 'and is not simply reset to empty');

    is($s{delivered} + $s{lapped}, $sent,
       'delivered plus lapped equals published - nothing vanished unaccounted');

    # And what survived is the NEWEST, which is what drop-oldest means.
    is($got[-1][1], $sent, 'the last record delivered is the last published');
    is($got[0][1], $sent - scalar(@got) + 1,
       'and the first is exactly as far back as the ring reaches');
}

# ---- a cursor that keeps up loses nothing over many laps -------------------
{
    my $r = $a->ring('keepup', slots => 8, slot_size => 128);
    my $c = $r->cursor;
    my $seen = 0;
    for my $i (1 .. 200) {
        $r->publish('n', $i);
        $seen += () = $c->drain;      # drain every time: never overtaken
    }
    my %s = $c->stats;
    is($seen, 200, 'a cursor that drains every publish sees every record');
    is($s{lapped}, 0, 'and is never lapped, however many times the ring wraps');
}

# ---- the ring's own count agrees with the cursors --------------------------
{
    my $r = $a->ring('counted', slots => 8, slot_size => 128);
    my $c = $r->cursor;
    $r->publish('n', $_) for 1 .. 50;
    my @got = $c->drain;
    my %rs  = $r->stats;
    my %cs  = $c->stats;
    is($rs{published}, 50, 'the ring counted every publish');
    is($cs{delivered} + $cs{lapped}, $rs{published},
       'and the cursor accounts for every one of them');
}

done_testing;
