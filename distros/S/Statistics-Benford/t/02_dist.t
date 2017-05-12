use strict;
use warnings;
use Test::More tests => 6;
use Statistics::Benford;

{
    my $stats = Statistics::Benford->new(2, 0, 1);
    is_deeply({$stats->dist}, {1 => 1}, 'dist: base=1, pos=0, len=1');
}

{
    my $stats = Statistics::Benford->new;

    my @e = qw(0.301 0.176 0.125 0.097 0.079 0.067 0.058 0.051 0.046);
    my %e = map { $_ => $e[ $_ - 1 ] } (1 .. 9);

    my %d = $stats->dist;
    while (my ($k, $v) = each %d) {
        $d{$k} = sprintf "%.3f", $v;
    }

    is_deeply(\%d, \%e, 'dist: base=10, pos=0, len=1');
}

{
    my $stats = Statistics::Benford->new(10, 1, 1);

    my @e = qw(0.120 0.114 0.109 0.104 0.100 0.097 0.093 0.090 0.088 0.085);
    my %e = map { $_ => $e[ $_ ] } (0 .. 9);

    my %d = $stats->dist;
    while (my ($k, $v) = each %d) {
        $d{$k} = sprintf "%.3f", $v;
    }

    is_deeply(\%d, \%e, 'dist: base=10, pos=1, len=1');
}

{
    my $stats = Statistics::Benford->new(10, 0, 2);

    my @e = qw(
        0.041 0.038 0.035 0.032 0.030 0.028 0.026 0.025 0.023 0.022 0.021
        0.020 0.019 0.018 0.018 0.017 0.016 0.016 0.015 0.015 0.014 0.014
        0.013 0.013 0.013 0.012 0.012 0.012 0.011 0.011 0.011 0.010 0.010
        0.010 0.010 0.010 0.009 0.009 0.009 0.009 0.009 0.008 0.008 0.008
        0.008 0.008 0.008 0.008 0.007 0.007 0.007 0.007 0.007 0.007 0.007
        0.007 0.007 0.006 0.006 0.006 0.006 0.006 0.006 0.006 0.006 0.006
        0.006 0.006 0.006 0.005 0.005 0.005 0.005 0.005 0.005 0.005 0.005
        0.005 0.005 0.005 0.005 0.005 0.005 0.005 0.005 0.005 0.005 0.004
        0.004 0.004
   );
    my %e = map { $_ => $e[ $_ - 10 ] } (10 .. 99);

    my %d = $stats->dist;
    while (my ($k, $v) = each %d) {
        $d{$k} = sprintf "%.3f", $v;
    }

    is_deeply(\%d, \%e, 'dist: base=10, pos=0, len=2');
}

{
    my $stats = Statistics::Benford->new(16, 0, 1);

    my @e = qw(
        0.250 0.146 0.104 0.080 0.066 0.056 0.048 0.042 0.038 0.034 0.031
        0.029 0.027 0.025 0.023
   );
    my %e = map { $_ => $e[ $_ - 1 ] } (1 .. 15);

    my %d = $stats->dist;
    while (my ($k, $v) = each %d) {
        $d{$k} = sprintf "%.3f", $v;
    }

    is_deeply(\%d, \%e, 'dist: base=16, pos=0, len=1');
}

{
    my $stats = Statistics::Benford->new(8, 0, 1);

    my @e = qw(0.333 0.195 0.138 0.107 0.088 0.074 0.064);
    my %e = map { $_ => $e[ $_ - 1 ] } (1..7);

    my %d = $stats->dist;
    while (my ($k, $v) = each %d) {
        $d{$k} = sprintf "%.3f", $v;
    }

    is_deeply(\%d, \%e, 'dist: base=8, pos=0, len=1');
}
