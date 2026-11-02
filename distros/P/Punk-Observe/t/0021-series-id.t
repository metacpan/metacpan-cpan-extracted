#!perl
# The series id. This is the property per-worker writing rests on: two workers
# that never communicate must reach the same id for the same label set.
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Config;
use Punk::Observe;

my $S = 'Punk::Observe::Segment';

sub c_hex {
    my ($buf, $seed) = @_;
    my ($hi, $lo) = $S->can('murmur128')->($buf, $seed // 0);
    return _hex($hi) . _hex($lo);
}
sub _hex {
    my ($v) = @_;
    # "$v" is a decimal string where a UV cannot hold it, so this goes through
    # Math::BigInt rather than sprintf('%x'), which would truncate.
    #
    # And the padding is done by hand: sprintf('%016s') pads with SPACES,
    # because the 0 flag applies to numeric conversions and not to %s. That
    # produced two implementations that "disagreed everywhere" when only the
    # formatting differed.
    #
    # as_hex, not to_hex: to_hex is Math::BigInt 1.999807, newer than the copy
    # perl 5.26 and older ship, and as_hex is in all of them.
    require Math::BigInt;
    (my $h = lc Math::BigInt->new("$v")->as_hex) =~ s/\A0x//;
    return ('0' x (16 - length $h)) . $h;
}

# --- the hash, cross-checked against an independent implementation ----------
#
# There is NO MurmurHash3 reference on this machine - no Digest::Murmur*, no
# python mmh3, nothing in the tree - so the C cannot be checked against a
# published constant here, and asserting vectors from memory would be the
# naive-probe mistake in its purest form: a fabricated vector either passes
# vacuously or fails for the wrong reason. (It failed for the wrong reason
# once while this file was being written, which is how the point got made.)
#
# So the check is a SECOND IMPLEMENTATION, in Perl, coded separately with
# different arithmetic. That catches implementation slips - a wrong rotation,
# a dropped tail case, a mis-ordered finalisation - and it does NOT catch a
# shared misreading of the algorithm, because both came from the same head.
# External vector verification remains owed, and is recorded as such.

SKIP: {
    skip 'the Perl reference needs 64-bit integers', 20 if $Config{uvsize} < 8;
    require POMurmur;

    # Every tail length 0..32 exercises each of the sixteen switch cases and
    # the block loop either side of them. This is where a hand-written tail
    # goes wrong, so it is covered exhaustively rather than sampled.
    my $bad = 0;
    for my $n (0 .. 32) {
        my $in = join '', map { chr(($_ * 31 + 7) & 0xFF) } 1 .. $n;
        $bad++ if c_hex($in, 0) ne POMurmur::hash128_hex($in, 0);
    }
    is($bad, 0, 'C and the Perl reference agree at every length 0 to 32');

    # Several block-loop iterations plus each tail.
    $bad = 0;
    for my $n (33 .. 80) {
        my $in = join '', map { chr(($_ * 17 + 3) & 0xFF) } 1 .. $n;
        $bad++ if c_hex($in, 0) ne POMurmur::hash128_hex($in, 0);
    }
    is($bad, 0, '  and at every length 33 to 80, across block boundaries');

    # Seeds must be honoured.
    $bad = 0;
    for my $seed (0, 1, 42, 0xFFFFFFFF) {
        $bad++ if c_hex('the quick brown fox', $seed)
               ne POMurmur::hash128_hex('the quick brown fox', $seed);
    }
    is($bad, 0, '  and for four different seeds');

    # High bytes and NULs, which a C-string bug would mangle.
    $bad = 0;
    for my $in ("\0", "\0\0\0", "a\0b", "\xff" x 16, "\x80\x00\xff\x7f" x 5) {
        $bad++ if c_hex($in, 0) ne POMurmur::hash128_hex($in, 0);
    }
    is($bad, 0, '  and for inputs full of NULs and high bytes');
}

# --- properties that hold regardless of the reference ----------------------

# Avalanche: a one-bit change in the input must change about half the output
# bits. A hash that failed this would still be deterministic and would still
# look fine in every test above.
{
    my $base = 'service=checkout,route=/pay,method=POST';
    my @flips;
    for my $bit (0 .. 63) {
        my $b = $base;
        my $byte = int($bit / 8);
        substr($b, $byte, 1) = chr(ord(substr($b, $byte, 1)) ^ (1 << ($bit % 8)));
        my $a = c_hex($base, 0);
        my $c = c_hex($b, 0);
        my $diff = 0;
        for my $i (0 .. 31) {
            my $x = hex(substr($a, $i, 1)) ^ hex(substr($c, $i, 1));
            $diff += sprintf('%b', $x) =~ tr/1//;
        }
        push @flips, $diff;
    }
    my $avg = 0; $avg += $_ for @flips; $avg /= scalar @flips;
    cmp_ok($avg, '>', 50, 'a one-bit input change flips over 50 of 128 bits');
    cmp_ok($avg, '<', 78, '  and fewer than 78, so it is near half');
    my @weak = grep { $_ < 30 } @flips;
    is(scalar @weak, 0, '  with no input bit flipping fewer than 30');
}

# --- the identity property --------------------------------------------------

# The same label block always gives the same id. Trivially true within one
# process; the point is that it is a pure function of the BYTES, with no
# counter, no state and nothing to coordinate.
{
    my @blocks = ("service\0api", "service\0web", "service\0api",
                  "service\0api\0route\0/x");
    my $a = $S->can('intern_series')->(\@blocks);
    my $b = $S->can('intern_series')->(\@blocks);
    is_deeply($a->{ids}, $b->{ids},
              'two independent interning runs agree on every id');
    is($a->{ids}[0], $a->{ids}[2], 'the same block gets the same id');
    isnt($a->{ids}[0], $a->{ids}[1], 'a different one does not');
    is($a->{count}, 3, 'four blocks are three series');
}

# ORDER OF ARRIVAL MUST NOT MATTER. Worker A sees these blocks in one order
# and worker B in another; they must still assign the same id to the same
# block. Only the dense SLOT differs, and a slot is segment-local by design.
{
    my @blocks = map { "service\0s$_" } 1 .. 20;
    my @rev    = reverse @blocks;

    my $fwd = $S->can('intern_series')->(\@blocks);
    my $bwd = $S->can('intern_series')->(\@rev);

    my %id_fwd; $id_fwd{ $blocks[$_] } = $fwd->{ids}[$_] for 0 .. $#blocks;
    my %id_bwd; $id_bwd{ $rev[$_] }    = $bwd->{ids}[$_] for 0 .. $#rev;

    is_deeply(\%id_fwd, \%id_bwd,
              'ids are identical whichever order the blocks arrive in');

    # The dense SLOT is assignment order, so it does differ - which is the
    # point of separating the two. A slot is segment-local bookkeeping; the id
    # is the identity that crosses workers. Compare the slot given to the SAME
    # block, not the slot at the same position.
    my %slot_fwd; $slot_fwd{ $blocks[$_] } = $fwd->{slots}[$_] for 0 .. $#blocks;
    my %slot_bwd; $slot_bwd{ $rev[$_] }    = $bwd->{slots}[$_] for 0 .. $#rev;
    isnt($slot_fwd{ $blocks[0] }, $slot_bwd{ $blocks[0] },
         '  while the same block gets a DIFFERENT slot in each order');
    is($id_fwd{ $blocks[0] }, $id_bwd{ $blocks[0] },
       '  and the same id, which is the property that matters');
}

# An id is 128 bits and all of them are used.
{
    my @blocks = map { "service\0s$_" } 1 .. 500;
    my $r = $S->can('intern_series')->(\@blocks);
    is($r->{count}, 500, '500 distinct blocks are 500 series');
    my %seen;
    $seen{$_}++ for @{ $r->{ids} };
    is(scalar keys %seen, 500, '  with 500 distinct ids and no collision');
    is(length($r->{ids}[0]), 32, '  each 32 hex characters, so 128 bits');

    # Both halves must actually vary. A bug that returned only h1 would still
    # look unique here without this.
    my %hi = map { substr($_, 0, 16) => 1 } @{ $r->{ids} };
    my %lo = map { substr($_, 16)    => 1 } @{ $r->{ids} };
    cmp_ok(scalar keys %hi, '>', 400, 'the high half varies');
    cmp_ok(scalar keys %lo, '>', 400, 'the low half varies');
}

# The empty block is a legitimate series - a record with no attributes at all.
{
    my $r = $S->can('intern_series')->(['', '', "x"]);
    is($r->{count}, 2, 'the empty label block is a series in its own right');
    is($r->{ids}[0], $r->{ids}[1], '  and is stable');
}

# --- the memcmp verify ------------------------------------------------------

# Blocks that differ ONLY in a trailing byte, in length, or in a NUL must be
# distinct series. This is what the full-block comparison protects: a hash
# match alone is not proof, and the failure it would hide is two unrelated
# services merged into one chart, which nobody would ever find.
{
    my @tricky = (
        "service\0api",
        "service\0api\0",          # trailing NUL
        "service\0ap",             # shorter
        "service\0apj",            # last byte differs
        "Service\0api",            # case
        "service\0api\0\0",
    );
    my $r = $S->can('intern_series')->(\@tricky);
    is($r->{count}, scalar @tricky,
       'blocks differing only subtly are all distinct series');
    my %seen; $seen{$_}++ for @{ $r->{ids} };
    is(scalar keys %seen, scalar @tricky, '  with distinct ids');
    is($r->{collisions}, 0, '  and no full-hash collisions in this set');
}

# Blocks containing NULs and high bytes are handled by length, never by a
# C-string convention. A label value can contain anything.
{
    my @binary = ("k\0\0\0v", "k\0\0\0w", "k" . chr(0xFF) . "v", "k\0v\0", "k\0v");
    my $r = $S->can('intern_series')->(\@binary);
    is($r->{count}, 5, 'binary label blocks are distinguished by length, not NUL');
}

# --- growth -----------------------------------------------------------------

# The table rehashes as it grows; every id must survive that.
{
    my @blocks = map { "service\0s$_" } 1 .. 5000;
    my $r = $S->can('intern_series')->(\@blocks);
    is($r->{count}, 5000, '5000 series intern without loss across rehashes');

    # And re-interning the same list gives the same ids, which is the property
    # that must survive the table doubling several times.
    my $again = $S->can('intern_series')->(\@blocks);
    is_deeply($r->{ids}, $again->{ids}, '  and the ids are reproducible');
}

# Interleaving new and repeated blocks across growth boundaries.
{
    my @mixed;
    for my $i (1 .. 2000) { push @mixed, "s$i"; push @mixed, "s1"; }
    my $r = $S->can('intern_series')->(\@mixed);
    is($r->{count}, 2000, 'repeats interleaved with new blocks still dedupe');
    my $first = $r->{ids}[1];
    my @s1 = grep { $mixed[$_] eq 's1' } 0 .. $#mixed;
    my $bad = grep { $r->{ids}[$_] ne $first } @s1;
    is($bad, 0, '  and every occurrence of the repeat has the same id');
}

done_testing();
