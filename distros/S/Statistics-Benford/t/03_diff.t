use strict;
use warnings;
use Test::More tests => 6;
use Statistics::Benford;

{
    my $stats = Statistics::Benford->new;
    my %freq = map {$_ => 99} (1 .. 9);

    my $diff = sprintf "%.3f", 0 + $stats->diff(%freq);
    cmp_ok($diff, '==', 0.537, 'scalar diff: 10, 0, 1');

    my @e = qw(-0.190 -0.065 -0.014 0.014 0.032 0.044 0.053 0.060 0.065);
    my %e = map { $_ => $e[ $_ -1 ] } (1 .. 9);

    my %d = $stats->diff(%freq);
    while (my ($k, $v) = each %d) {
        $d{$k} = sprintf "%.3f", $v;
    }

    is_deeply(\%d, \%e ,'list diff: 10, 0, 1');
}

{
    my $stats = Statistics::Benford->new(10, 1, 1);
    my %freq = map {$_ => 99} (0 .. 9);

    my $diff = sprintf "%.3f", 0 + $stats->diff(%freq);
    cmp_ok($diff, '==', 0.094, 'scalar diff: 10, 1, 1');

    my @e = qw(
        -0.020 -0.014 -0.009 -0.004 -0.000 0.003 0.007 0.010 0.012 0.015
   );
    my %e = map { $_ => $e[ $_ ] } (0 .. 9);

    my %d = $stats->diff(%freq);
    while (my ($k, $v) = each %d) {
        $d{$k} = sprintf "%.3f", $v;
    }

    is_deeply(\%d, \%e ,'list diff: 10, 1, 1');
}

{
    my $stats = Statistics::Benford->new(10, 0, 2);
    my %freq = map {$_ => 99} (10 .. 99);

    my $diff = sprintf "%.3f", 0 + $stats->diff(%freq);
    cmp_ok($diff, '==', 0.538, 'scalar diff: 10, 0, 2');

    my @e = qw(
        -0.030 -0.027 -0.024 -0.021 -0.019 -0.017 -0.015 -0.014 -0.012 -0.011
        -0.010 -0.009 -0.008 -0.007 -0.007 -0.006 -0.005 -0.005 -0.004 -0.004
        -0.003 -0.003 -0.002 -0.002 -0.001 -0.001 -0.001 -0.000 -0.000 0.000
        0.000 0.001 0.001 0.001 0.001 0.002 0.002 0.002 0.002 0.002 0.003
        0.003 0.003 0.003 0.003 0.003 0.003 0.004 0.004 0.004 0.004 0.004
        0.004 0.004 0.004 0.004 0.005 0.005 0.005 0.005 0.005 0.005 0.005
        0.005 0.005 0.005 0.005 0.006 0.006 0.006 0.006 0.006 0.006 0.006
        0.006 0.006 0.006 0.006 0.006 0.006 0.006 0.006 0.006 0.006 0.007
        0.007 0.007 0.007 0.007 0.007
   );
    my %e = map { $_ => $e[ $_ - 10 ] } (10 .. 99);

    my %d = $stats->diff(%freq);
    while (my ($k, $v) = each %d) {
        $d{$k} = sprintf "%.3f", $v;
    }

    is_deeply(\%d, \%e ,'list diff: 10, 0, 2');
}
