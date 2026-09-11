#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Shared::Arena ();

# THE TEST THIS DIST EXISTS TO BE ABLE TO WRITE.
#
# Map one named region TWICE IN ONE PROCESS, write through the first mapping,
# read through the second. If anything inside the region is stored as a pointer
# rather than an offset, the second mapping follows an address that means
# something else - or nothing - and this fails.
#
# No fork and no race, so it fails the same way every time. That is the whole
# point: the equivalent bug in a design that stores absolute pointers can only
# be provoked by a second mapping at a second address, which such a design has
# no way to produce, so it ships and is discovered by a consumer years later.

plan skip_all => 'no atomics in this build' unless Shared::Arena::have_atomics();
plan skip_all => 'named regions are POSIX or Windows only'
    if $^O eq 'cygwin';

my $name = "sa-reloc-$$";
Shared::Arena->destroy($name);   # a previous run that died holding it

my $a = Shared::Arena->create(name => $name, size => 256 * 1024);
ok($a, 'created a named region') or BAIL_OUT('nothing to test against');
ok($a->created, 'and this process is its creator');

my ($off, $len) = $a->region('probe', size => 4096);
ok($off, 'carved a sub-region') or BAIL_OUT('nothing to write into');
is($len, 4096, 'of the size asked for');

# THE CHEAP HALF OF THE PROOF, and the one that cannot be fooled.
#
# Everything below writes through one mapping and reads through another, which
# is the behaviour we want - but both mappings are live in this one address
# space, so an absolute pointer stored by the first would still resolve when
# followed by the second, and every assertion after this one would pass with
# the bug present. So assert the shape of the number itself: an offset is
# smaller than the region, an address is not.
cmp_ok($off, '<', $a->size,
       'the offset is an offset - smaller than the region - and not an address');

# The second mapping. Same name, same process.
my $b = Shared::Arena->attach($name);
ok($b, 'attached the same region a second time in one process');
ok(!$b->created, 'the second mapping did not create it');

# If these two were the same address the test would prove nothing at all: a
# stored pointer would work by accident. The mapping is a fresh mmap, so the
# kernel is under no obligation to place it anywhere in particular - but say so
# rather than assuming, because a run where they coincide is a run where the
# rest of this file is vacuous.
if ($a->base == $b->base) {
    plan skip_all => 'both mappings landed at the same address, so this run '
                   . 'cannot distinguish an offset from a pointer';
}
isnt($a->base, $b->base, 'and it landed at a different address');

# The registry itself is the first thing that has to survive the crossing: the
# second mapping found 'probe' by name, through reg_off, without ever having
# been told where it is.
my ($boff, $blen) = $b->region('probe');
is($boff, $off, 'the second mapping resolves the region to the same offset');
is($blen, $len, 'and the same length');

is_deeply([sort $b->regions], ['probe'],
          'and lists the same carved names');

# Now the bytes. Written through one mapping, read through the other.
my $msg = "written through mapping A at " . $a->base;
$a->poke('probe', 0, $msg);
is($b->peek('probe', 0, length $msg), $msg,
   'bytes written through one mapping are read through the other');

# And back the other way, at a non-zero offset, so a design that got the base
# right but the offset arithmetic wrong is caught too.
my $reply = "and back through B";
$b->poke('probe', 1024, $reply);
is($a->peek('probe', 1024, length $reply), $reply,
   'and in the other direction, at an offset');

# A region carved through the SECOND mapping must be visible through the first,
# which exercises the registry's write path across the address difference.
my ($coff) = $b->region('late', size => 512);
ok($coff, 'the second mapping can carve too');
my ($aoff) = $a->region('late');
is($aoff, $coff, 'and the first mapping sees the new region at the same offset');
isnt($coff, $off, 'which is not the first region');

# ---- and the case the two mappings above cannot stand in for ---------------
#
# An INDEPENDENT process. Not a fork child, so it inherits nothing, and this
# region's address in it has no relationship to ours. This is the arrangement a
# named region exists for, and the only one where a stored pointer is certain
# to be meaningless rather than merely different.
SKIP: {
    my $child = <<'CODE';
use strict; use warnings;
use Shared::Arena ();
my $a = Shared::Arena->attach($ARGV[0]) or die "attach failed\n";
die "created\n" if $a->created;
print $a->peek('probe', 0, length $ARGV[1]), "\n";
$a->poke('probe', 2048, "from pid $$ at " . $a->base);
print $a->base, "\n";
CODE

    my @inc = map { "-I$_" } grep { !ref } @INC;
    my $tmp = "sa-child-$$.pl";
    open my $fh, '>', $tmp or skip "cannot write $tmp: $!", 4;
    print {$fh} $child;
    close $fh;

    my @out = `"$^X" @inc "$tmp" "$name" "$msg" 2>&1`;
    my $rc  = $?;
    unlink $tmp;

    is($rc, 0, 'an unrelated process attached the region') or diag @out;
    chomp @out;
    is($out[0], $msg,
       'and read what this process wrote, with no fork between them');
    ok(defined $out[1] && $out[1] ne $a->base,
       'and had it mapped at an address of its own') or
        diag "child base $out[1], ours " . $a->base;
    like($a->peek('probe', 2048, 64), qr/^from pid \d+ at \d+/,
         'and what it wrote is here, after it exited');
}

undef $a;
undef $b;
Shared::Arena->destroy($name);

done_testing;
