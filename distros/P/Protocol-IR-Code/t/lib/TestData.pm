package TestData;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(pronto_to_pairs);

# Convert a Pronto hex string into microsecond mark/space burst pairs,
# matching the shape fed to Protocol::IR::*::decode_timing.
sub pronto_to_pairs {
    my ($pronto) = @_;
    my @t = split /\s+/, $pronto;
    my $period = 1000000.0 / int(1000000.0 / (hex($t[1]) * 0.241246));
    my $pairs  = hex($t[2]) + hex($t[3]);
    my @bp;
    for (my $i = 0; $i < $pairs; $i++) {
        my $idx = 4 + ($i * 2);
        push @bp, [hex($t[$idx]) * $period, hex($t[$idx + 1]) * $period];
    }
    return \@bp;
}

1;
