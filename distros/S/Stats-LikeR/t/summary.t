#!/usr/bin/env perl
# Coverage for the under-tested paths of summary():
#   * the FLAT-LIST calling form  summary(1,2,3)  and  summary(@x, nrows => N)
#     where trailing named args must be peeled off the argument list, and
#   * the three structural branches (single array, AoA, hash) plus the
#     "undefined value" guard.
# Assertions are structural (shape, headers, row counts, dies) so they hold
# regardless of the exact numbers the XS stat routines produce.
use strict;
use warnings;
use Test::More;
use Stats::LikeR qw(summary);

# summary prints to STDOUT; silence it while capturing the returned arrayref.
sub quiet_summary {
    my @args = @_;
    my $out = '';
    open my $old, '>&', \*STDOUT or die $!;
    close STDOUT;
    open STDOUT, '>', \$out or die $!;
    my $r = summary(@args);
    open STDOUT, '>&', $old or die $!;
    return $r;
}

# --- flat list of scalars (no reference) ----------------------------------
{
    my $r = quiet_summary(1, 2, 3, 4, 5);
    is ref($r), 'ARRAY', 'flat list returns an arrayref';
    my $txt = join "\n", @$r;
    like $txt, qr/Median/, 'single-array header present';
    unlike $txt, qr/\bIndex\b/, 'flat list treated as one vector, not an AoA';
    is $r->[0], '-' x 75, 'single-array layout starts with a rule';
}

# --- flat list WITH a trailing named arg (the peel-off while-loop) ---------
{
    # nrows must be consumed as an option, NOT counted as data.
    my $with    = quiet_summary(1, 2, 3, nrows => 2);
    my $without = quiet_summary(1, 2, 3);
    is ref($with), 'ARRAY', 'flat list + nrows still returns arrayref';
    is_deeply $with, $without,
        'trailing nrows is peeled off, not folded into the data';

    # nrow is accepted as a synonym for nrows
    is ref(quiet_summary(1, 2, 3, nrow => 1)), 'ARRAY', 'nrow synonym accepted';
}

# --- array reference of scalars (single array path) -----------------------
{
    my $r = quiet_summary([10, 20, 30, 40]);
    like join("\n", @$r), qr/Median/, 'arrayref single-vector summary';
    unlike join("\n", @$r), qr/\bIndex\b/, 'arrayref of scalars is single-array';
}

# --- array of arrays (per-index rows, "Index" column) ---------------------
{
    my $r = quiet_summary([ [1, 2, 3, 4], [5, 6, 7, 8] ]);
    like join("\n", @$r), qr/\bIndex\b/, 'AoA layout adds an Index column';
}

# --- hash of arrays (per-key rows, "Key" column) --------------------------
{
    my $r = quiet_summary({ A => [1, 2, 3], B => [4, 5, 6] });
    like join("\n", @$r), qr/\bKey\b/, 'hash layout adds a Key column';
}

# --- nrows actually caps the number of printed data rows (AoA) ------------
{
    my $aoa = [ map { [ 1 .. 5 ] } 1 .. 5 ];      # 5 index-rows available
    my $r = quiet_summary($aoa, nrows => 2);
    my @data = grep { /^\s*\d/ } @$r;             # rows beginning with an index
    is scalar(@data), 2, 'nrows caps AoA rows to 2';
}

# --- error paths ----------------------------------------------------------
{
    eval { quiet_summary(\"scalar-ref") };
    like $@, qr/must either be a hash or an array/, 'die: bad reference type';

    eval { quiet_summary([1, undef, 3]) };
    like $@, qr/not defined/, 'die: undefined value in a single vector';
}

done_testing;
