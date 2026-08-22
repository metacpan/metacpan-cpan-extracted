use strict;
use warnings;
use Test::More;
use QR::Code;

# The PBM serialiser round-trips to the matrix.

my $data = 'pbm round trip';

for my $quiet (4, 2, 0) {
    my ($mod, undef, undef, undef, $size) = QR::Code->matrix($data);
    my $pbm = QR::Code->pbm($data, quiet => $quiet);
    my @lines = split /\n/, $pbm;
    my $span = $size + 2 * $quiet;

    is(shift @lines, 'P1', "quiet $quiet: P1 magic");
    is(shift @lines, "$span $span", "quiet $quiet: dimensions");
    is(scalar @lines, $span, "quiet $quiet: row count");

    my $bad = 0;
    for my $y (0 .. $span - 1) {
        my @cells = split ' ', $lines[$y];
        for my $x (0 .. $span - 1) {
            my $r = $y - $quiet;
            my $c = $x - $quiet;
            my $want = ($r >= 0 && $r < $size && $c >= 0 && $c < $size)
                     ? $mod->[$r][$c] : 0;
            $bad++ if $cells[$x] != $want;
        }
    }
    is($bad, 0, "quiet $quiet: every cell round-trips");
}

done_testing;
