use strict;
use warnings;
use Test::More;
use QR::Code;

# Version selection at the boundaries. The character count indicator
# widens at version 10, so the arithmetic changes exactly inside the
# supported range - these tests exist mostly for that seam.

my %ECC = (L => 0, M => 1, Q => 2, H => 3);

sub picked_version {
    my ($payload, $ecc) = @_;
    my (undef, undef, $version) = QR::Code->matrix($payload, ecc => $ecc);
    return $version;
}

for my $ecc (qw(L M Q H)) {
    for my $v (1 .. 14) {
        my $cap = QR::Code::_capacity($ECC{$ecc}, $v);

        cmp_ok picked_version('x' x $cap, $ecc), '<=', $v,
            "ecc $ecc: $cap bytes fit within v$v";
        cmp_ok picked_version('x' x ($cap + 1), $ecc), '>', $v,
            "ecc $ecc: one byte more grows past v$v";
    }

    my $max = QR::Code::_capacity($ECC{$ecc}, 15);
    my $err = do {
        local $@;
        eval { QR::Code->svg('x' x ($max + 1), ecc => $ecc) };
        $@;
    };
    like $err, qr/exceeds the \d+ byte capacity of version 15/,
        "ecc $ecc: one byte past v15 refuses rather than truncating";
}

# forcing a version that is too small refuses too
my $err = do {
    local $@;
    eval { QR::Code->svg('x' x 100, ecc => 'H', version => 1) };
    $@;
};
like $err, qr/exceeds the \d+ byte capacity of version 1 at ECC H/,
    'forced-version overflow refuses';

# and out-of-range versions are caught before the encoder sees them -
# without numifying the junk first, which would warn before the croak
for my $bad (0, 16, 'seven') {
    my @warn;
    my $e = do {
        local $SIG{__WARN__} = sub { push @warn, @_ };
        local $@;
        eval { QR::Code->svg('x', version => $bad) };
        $@;
    };
    like $e, qr/version must be 1 to 15/, "version '$bad' refused";
    is_deeply \@warn, [], "version '$bad' refused without warning";
}

done_testing;
