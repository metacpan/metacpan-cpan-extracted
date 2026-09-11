#!perl
use strict;
use warnings;
use FindBin ();
# Prefer the sibling Frozen build: the ABI lands there first and an
# installed copy may still be a version behind. Harmless when it is not.
use lib "$FindBin::Bin/../../Frozen/blib/lib";
use lib "$FindBin::Bin/../../Frozen/blib/arch";
use lib "$FindBin::Bin/lib";
use Test::More;
use Config ();

# Frozen's C ABI, from both ends.
#
# Punk holds its i18n catalogues in a Frozen block and reads them through
# fz_abi.h rather than through Frozen's Perl surface, because a Perl frame
# per lookup is the cost punk_i18n.h exists to avoid.
#
# The dependency is HARD: there is no arena to fall back to, because the
# block is the arena. So there is no "degrades gracefully" case to test.
# What is tested is that the two ends agree, and that a version older than
# the one Punk was compiled against is REFUSED rather than used.

BEGIN {
    eval { require Punk; 1 } or plan skip_all => 'Punk did not load';
}

my $have = eval { require Frozen; Frozen::_abi_version() };
plan skip_all => 'Frozen not available' unless defined $have;

my $want = Punk::_fz_abi_version();

# ---- the two ends ------------------------------------------------------------
{
    cmp_ok($want, '>=', 2,
        'Punk was compiled against FZ_ABI_VERSION 2 or later');

    ok(Frozen->can('_abi_ptr'), 'the provider end publishes _abi_ptr');
    cmp_ok($have, '>=', 1, 'and answers with an ABI version');

    my ($step) = Frozen::_abi_selftest();
    is($step, 0, "the provider's own table self-test passes")
        or diag "FZ_STEP $step - see Frozen/include/fz/fz_abi_impl.h";
}

# ---- resolution, which is a real version check and not a simulated one -------
SKIP: {
    skip "Frozen exposes ABI v$have, Punk needs v$want "
       . "(build and install the sibling Frozen)", 2
        if $have < $want;

    is(Punk::_fz_available(), 1, 'Punk resolves the table on first use');
    is(Punk::_fz_available(), 1, '...and the one-shot resolve is stable');
}

# ---- the guard refuses a table that is too old -------------------------------
#
# In a child, because the resolve happens once per process behind a
# _TRIED flag and cannot be undone in this one. t/0010-abi-guard.t takes
# the same approach for the same reason.
{
    my $perl = $Config::Config{perlpath} || $^X;
    my @inc  = map { "-I$_" } grep { !ref } @INC;
    my $out  = do {
        local $ENV{PUNK_FAKE_FZ_BAD} = 1;
        `"$perl" @inc -MPunk -e "print Punk::_fz_available() ? 1 : 0" 2>&1`;
    };
    chomp $out;
    is($out, '0', 'PUNK_FAKE_FZ_BAD makes the guard refuse the table')
        or diag "child said: $out";
}

# The croak from punk_fz() is not asserted here because nothing calls it
# yet - this phase adds a resolver and no caller. It is tested with its
# first caller, when the plugin's register starts building a block.

done_testing;
