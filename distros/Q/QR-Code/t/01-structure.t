use strict;
use warnings;
use Test::More;
use QR::Code;

# Structural invariants of every symbol the encoder can produce, checked
# against the specification rather than against the encoder: sizes,
# finder patterns, separators, timing patterns, the dark module. A
# symbol can pass all of this and still be wrong - t/04 decodes the
# payload back - but nothing can pass t/04 while failing this without
# the decoder sharing the bug, which is exactly how the format-info bug
# survived the first verification round.

my %ECC = (L => 0, M => 1, Q => 2, H => 3);

for my $ecc (qw(L M Q H)) {
    for my $v (1 .. 15) {
        my $cap = QR::Code::_capacity($ECC{$ecc}, $v);
        my $payload = join '', map { chr(65 + $_ % 26) } 0 .. $cap - 1;
        my $m = QR::Code->matrix($payload, ecc => $ecc, version => $v);
        my $size = 17 + 4 * $v;

        subtest "v$v/$ecc at capacity ($cap bytes)" => sub {
            is scalar @$m, $size, "height $size";
            is scalar @{ $m->[0] }, $size, "width $size";

            # finder centres dark, separator corners light
            ok $m->[3][3],          'finder centre top-left';
            ok $m->[3][$size-4],    'finder centre top-right';
            ok $m->[$size-4][3],    'finder centre bottom-left';
            ok !$m->[7][7],         'separator top-left';
            ok !$m->[7][$size-8],   'separator top-right';
            ok !$m->[$size-8][7],   'separator bottom-left';

            # timing patterns alternate, dark on even coordinates
            my $bad = 0;
            for my $i (8 .. $size - 9) {
                $bad++ if $m->[6][$i] != (($i % 2) == 0 ? 1 : 0);
                $bad++ if $m->[$i][6] != (($i % 2) == 0 ? 1 : 0);
            }
            is $bad, 0, 'timing patterns';

            ok $m->[$size-8][8], 'the dark module';
        };
    }
}

done_testing;
