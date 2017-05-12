use strict;
use warnings;
use Test::More tests => 6;
use constant EPS => 1e-9;

BEGIN { use_ok('Statistics::Autocorrelation') };

my $acorr = Statistics::Autocorrelation->new();
isa_ok($acorr, 'Statistics::Autocorrelation');

my %refvals = (
    coeff_1 => -.5,
);

my @data = (1, 2);

my $coeff;

$coeff = $acorr->coefficient(data => \@data, lag => 1, unbias => 0, exact => 0, circular => 0);
ok( about_equal($coeff, $refvals{'coeff_1'}), "Coefficient lag 1: $coeff = $refvals{'coeff_1'}");

my $coeff_default = $acorr->coefficient(data => \@data, lag => 1);
ok($coeff == $coeff_default, "Default args do not return expected result");
 
# Check alias:
$coeff = $acorr->coeff(data => \@data, lag => 1);
ok( about_equal($coeff, $refvals{'coeff_1'}), "Coefficient lag 1 (by alias): $coeff = $refvals{'coeff_1'}");

# use Statistics::Data methods:
$acorr->load(\@data);
$coeff = $acorr->coeff(index => 0, lag => 1);
ok( about_equal($coeff, $refvals{'coeff_1'}), "Coefficient lag 1 (by alias): $coeff = $refvals{'coeff_1'}");

sub about_equal {
    return 0 if ! defined $_[0] || ! defined $_[1];
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}
1;