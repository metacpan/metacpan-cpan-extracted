use strict;
use warnings;
use Test::More;
use QR::Code;

# Structural assertions on the encoded matrix: the patterns a decoder
# needs to find the grid, checked cell by cell.

my $uri = 'otpauth://totp/Example:alice@example.com'
        . '?secret=JBSWY3DPEHPK3PXP&issuer=Example';

sub finder_expected {
    my ($r, $c) = @_;    # 0..6 within the finder
    return 1 if $r >= 2 && $r <= 4 && $c >= 2 && $c <= 4;
    return 1 if $r == 0 || $r == 6 || $c == 0 || $c == 6;
    return 0;
}

for my $ecc (qw(L M Q H)) {
    my ($mod, $fixed, $version, $mask, $size) =
        QR::Code->matrix($uri, ecc => $ecc);

    is($size, 17 + 4 * $version, "ecc $ecc: size matches version $version");
    is(scalar @$mod, $size, "ecc $ecc: row count");
    ok($mask >= 0 && $mask <= 7, "ecc $ecc: mask $mask in range");

    # the three finders, module for module
    my $bad = 0;
    for my $r (0 .. 6) {
        for my $c (0 .. 6) {
            my $want = finder_expected($r, $c);
            $bad++ if $mod->[$r][$c] != $want;
            $bad++ if $mod->[$r][$size - 7 + $c] != $want;
            $bad++ if $mod->[$size - 7 + $r][$c] != $want;
        }
    }
    is($bad, 0, "ecc $ecc: three finder patterns exact");

    # separators light
    $bad = 0;
    for my $i (0 .. 7) {
        $bad++ if $mod->[7][$i] || $mod->[$i][7];
        $bad++ if $mod->[7][$size - 1 - $i] || $mod->[$i][$size - 8];
        $bad++ if $mod->[$size - 8][$i] || $mod->[$size - 1 - $i][7];
    }
    is($bad, 0, "ecc $ecc: separators light");

    # timing patterns alternate, dark on even coordinates
    $bad = 0;
    for my $i (8 .. $size - 9) {
        $bad++ if $mod->[6][$i] != (($i % 2) == 0 ? 1 : 0);
        $bad++ if $mod->[$i][6] != (($i % 2) == 0 ? 1 : 0);
    }
    is($bad, 0, "ecc $ecc: timing patterns alternate");

    # the dark module
    is($mod->[4 * $version + 9][8], 1, "ecc $ecc: dark module present");
    is($fixed->[4 * $version + 9][8], 1, "ecc $ecc: dark module fixed");

    # function map marks the finders and timing
    ok($fixed->[0][0] && $fixed->[6][$size - 1] && $fixed->[$size - 1][6],
       "ecc $ecc: function map covers finders and timing");
}

# version selection: v1 at M holds 14 bytes, one more bumps to v2
{
    my (undef, undef, $v14) = QR::Code->matrix('a' x 14, ecc => 'M');
    my (undef, undef, $v15) = QR::Code->matrix('a' x 15, ecc => 'M');
    is($v14, 1, '14 bytes at M fits version 1');
    is($v15, 2, 'one byte over bumps to version 2');
}

# the ceiling: v15 at H holds 220 bytes and refuses 221
{
    my (undef, undef, $v) = QR::Code->matrix('a' x 220, ecc => 'H');
    is($v, 15, '220 bytes at H fits version 15');
    eval { QR::Code->matrix('a' x 221, ecc => 'H') };
    like($@, qr/exceeds the 220 byte capacity of version 15 at ECC H/,
         'one byte over the ceiling croaks with the numbers');
}

# forcing a version
{
    my (undef, undef, $v, undef, $size) =
        QR::Code->matrix('hi', version => 10);
    is($v, 10, 'forced version honoured');
    is($size, 57, 'version 10 is 57 modules');
    eval { QR::Code->matrix('a' x 100, ecc => 'H', version => 5) };
    like($@, qr/exceeds the \d+ byte capacity of version 5 at ECC H/,
         'payload too big for a forced version croaks');
}

# every version 1..15 reachable and sized right
for my $v (1 .. 15) {
    my $cap_probe = 'a' x 7;    # fits v1 at H
    my (undef, undef, $got, undef, $size) =
        QR::Code->matrix($cap_probe, version => $v);
    is($got, $v, "version $v encodes");
    is($size, 17 + 4 * $v, "version $v sized " . (17 + 4 * $v));
}

# argument validation
eval { QR::Code->matrix('x', ecc => 'Z') };
like($@, qr/ecc must be L, M, Q or H/, 'bad ecc croaks');
eval { QR::Code->matrix('x', version => 16) };
like($@, qr/version must be 1 to 15/, 'version 16 croaks');
eval { QR::Code->matrix('x', frobnicate => 1) };
like($@, qr/unknown matrix option 'frobnicate'/, 'unknown option croaks');

done_testing;
