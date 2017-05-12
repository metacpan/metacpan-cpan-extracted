use strict;
use warnings;
use Test::More tests => 6;
use Statistics::Benford;

{
    my $stats = Statistics::Benford->new(10, 0, 1);
    my %freq = map {$_ => 99} (1 .. 9);

    my $diff = sprintf "%.3f", 0 + $stats->signif(%freq);
    cmp_ok($diff, '==', 5.848, 'scalar signif: 10, 0, 1');

    my @e = qw(12.322 5.048 1.198 1.376 3.468 5.208 6.712 8.048 9.256);
    my %e = map { $_ => $e[ $_ - 1 ] } (1 .. 9);

    my %d = $stats->signif(%freq);
    while (my ($k, $v) = each %d) {
        $d{$k} = sprintf "%.3f", $v;
    }

    is_deeply(\%d, \%e ,'list signif: 10, 0, 1');
}

{
    my $stats = Statistics::Benford->new(10, 1, 1);
    my %freq = map {$_ => 99} (0..9);

    my $diff = sprintf "%.3f", 0 + $stats->signif(%freq);
    cmp_ok($diff, '==', 0.938, 'scalar signif: 10, 1, 1');

    my @e = qw(1.859 1.326 0.840 0.394 0.032 0.300 0.662 1.003 1.327 1.636);
    my %e = map { $_ => $e[ $_ ] } (0 .. 9);

    my %d = $stats->signif(%freq);
    while (my ($k, $v) = each %d) {
        $d{$k} = sprintf "%.3f", $v;
    }

    is_deeply(\%d, \%e ,'list signif: 10, 1, 1');
}

{
    my $stats = Statistics::Benford->new(10, 0, 2);
    my %freq = map {$_ => 99} (10 .. 99);

    my $diff = sprintf "%.3f", 0 + $stats->signif(%freq);
    cmp_ok($diff, '==', 5.467, 'scalar signif: 10, 0, 2');

    my @e = qw(
        14.323 13.178 12.159 11.241 10.407 9.643 8.938 8.285 7.676 7.105 6.569
        6.062 5.583 5.127 4.693 4.279 3.883 3.503 3.138 2.787 2.448 2.122 1.806
        1.500 1.204 0.916 0.637 0.366 0.102 0.054 0.303 0.547 0.784 1.017 1.244
        1.466 1.683 1.896 2.104 2.309 2.509 2.706 2.900 3.090 3.276 3.460 3.640
        3.818 3.993 4.165 4.334 4.501 4.666 4.828 4.988 5.146 5.302 5.455 5.607
        5.757 5.905 6.051 6.195 6.338 6.479 6.619 6.756 6.893 7.028 7.161 7.293
        7.424 7.554 7.682 7.809 7.934 8.059 8.182 8.304 8.425 8.545 8.664 8.782
        8.899 9.015 9.129 9.243 9.356 9.468 9.580
   );
    my %e = map { $_ => $e[ $_ - 10 ] } (10 .. 99);

    my %d = $stats->signif(%freq);
    while (my ($k, $v) = each %d) {
        $d{$k} = sprintf "%.3f", $v;
    }

    is_deeply(\%d, \%e ,'list signif: 10, 0, 2');
}
