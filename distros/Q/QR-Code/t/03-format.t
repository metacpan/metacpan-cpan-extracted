use strict;
use warnings;
use Test::More;
use QR::Code;

# The format information block, read back from the placed modules by an
# independent reimplementation. This field is where the one bug that
# survived the original verification round lived: the encoder wrote the
# fifteen bits LSB-first, every internal check agreed with it, and no
# real decoder could read a single symbol. The convention is therefore
# pinned here twice over:
#
#   - qr_format_bits(M, 0) must be 0x5412 - the specification's own XOR
#     mask, published in ISO/IEC 18004, so it cannot drift with the
#     implementation;
#   - the bit at (8,0) must be the MSB, verified byte-for-byte against
#     qrencode's output when the bug was found.

sub bch_format {
    my ($eccbits, $mask) = @_;
    my $d = ($eccbits << 3) | $mask;
    my $r = $d;
    $r = (($r << 1) ^ ((($r >> 9) & 1) * 0x537)) & 0x7FF for 1 .. 10;
    return ((($d << 10) | ($r & 0x3FF)) ^ 0x5412) & 0x7FFF;
}

my %ECCBITS = (L => 1, M => 0, Q => 3, H => 2);

is bch_format(0, 0), 0x5412,
    'format(M, mask 0) is 0x5412, the published anchor';

# distance property of the whole code
my @all = map { my $e = $_; map { bch_format($e, $_) } 0 .. 7 } 0 .. 3;
my $min = 15;
for my $i (0 .. $#all) {
    for my $j ($i + 1 .. $#all) {
        my $x = $all[$i] ^ $all[$j];
        my $d = 0;
        $d += ($x >> $_) & 1 for 0 .. 14;
        $min = $d if $d < $min;
    }
}
is $min, 7, 'the 32 format words have minimum Hamming distance 7';

# read the placed bits back MSB-first from both copies, on symbols small
# and large enough to bracket the version-info boundary
for my $spec ([qq(HELLO), q(M)], [qq(HELLO), q(H)], [q(x) x 150, q(H)]) {
    my ($payload, $ecc) = @$spec;
    my ($m, undef, $v, $mask, $size) = QR::Code->matrix($payload, ecc => $ecc);

    my $want = bch_format($ECCBITS{$ecc}, $mask);

    my @c1 = ([8,0],[8,1],[8,2],[8,3],[8,4],[8,5],[8,7],[8,8],
              [7,8],[5,8],[4,8],[3,8],[2,8],[1,8],[0,8]);
    my $got1 = 0;
    $got1 = ($got1 << 1) | $m->[$_->[0]][$_->[1]] for @c1;

    my @c2 = (map([$size - 1 - $_, 8], 0 .. 6),
              map([8, $size - 8 + $_], 0 .. 7));
    my $got2 = 0;
    $got2 = ($got2 << 1) | $m->[$_->[0]][$_->[1]] for @c2;

    subtest "v$v/$ecc mask $mask" => sub {
        is sprintf('%015b', $got1), sprintf('%015b', $want),
            'first copy, MSB first from (8,0)';
        is sprintf('%015b', $got2), sprintf('%015b', $want),
            'second copy, 7 up the right column + 8 along the bottom';
    };
}

done_testing;
