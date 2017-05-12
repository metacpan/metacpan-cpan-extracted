use strict;
use warnings;
use Test::More tests => 17;
use constant EPS => 1e-3;

# Test return of accurate coefficients using coeffs drawn from PASW software:

BEGIN { use_ok('Statistics::Autocorrelation') };

my $acorr = Statistics::Autocorrelation->new();

# sample data are the run-scores from Riess (1939, Journal of Parapsychology):
my @data = (5,7,10,12,15,8,16,13,18,21,11,15,19,24,21,21,22,24,25,24,21,20,19,20,18,14,15,15,16,12,19,21,22,24,20,18,22,21,19,19,16,21,22,17,16,18,19,21,20,19,16,21,23,19,17,21,21,18,15,14,18,18,19,18,17,18,19,20,20,20,19,20,21,21);

# coefficients per lag are those returned by SPSS with default settings:
my %coeffs = (1 => .615, 2 => .390, 3 => .309, 4 => .295, 5 => .311, 6 => .049, 7 => -.105, 8 => -.197, 9 => -.103, 10 => -.042, 11 => -.189, 12 => -.317, 13 => -.271, 14 => -.112, 15 => -.042, 16 => -.125);

my $coeff;

for my $k(1 .. 16) {
    $coeff = $acorr->coefficient(data => \@data, lag => $k);
    ok( about_equal($coeff, $coeffs{$k}), "Coefficient lag $k: $coeff = $coeffs{$k}");
}

sub about_equal {
    return 0 if ! defined $_[0] || ! defined $_[1];
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}
1;