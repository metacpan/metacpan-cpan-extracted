use 5.016;
use strict;
use warnings;

use rlib;
use List::Util qw /sum/;
use Math::Random::MT::Auto;
use Statistics::Descriptive;

use Statistics::Sampler::Multinomial;
use Statistics::Sampler::Multinomial::AliasMethod;

my $base_prng = Math::Random::MT::Auto->new ();

my @data = grep {$_ % 2} reverse (1..100);
$base_prng->shuffle (\@data);

my $data_sum = sum (@data);
my @scaled_data = map {$_ / $data_sum} @data;
my $n_samples = 10_000_000;
#$n_samples = $data_sum;

my $SSM = Statistics::Sampler::Multinomial->new(
    data => \@scaled_data,
    prng => $base_prng->clone,
);
my $SSMA = Statistics::Sampler::Multinomial::AliasMethod->new(
    data => \@scaled_data,
    prng => $base_prng->clone,
);

my $ssm_res  = $SSM->draw_n_samples ($n_samples);
my $ssma_res = $SSMA->draw_n_samples ($n_samples);
#my $ssma_res = [(1) x @data];

my (@ssm_diffs, @ssma_diffs);
my ($ssm_chisq, $ssma_chisq);
foreach my $i (0 .. $#data) {
    #my $denom = $n_samples * $scaled_data[$i] * (1 - $scaled_data[$i]);
    $ssm_diffs[$i] = ($ssm_res->[$i] / $n_samples) - $scaled_data[$i];
    my $expected = $scaled_data[$i] * $n_samples;
    $ssm_chisq += (($ssm_res->[$i] - $expected)**2) / $expected;
    
    $ssma_diffs[$i] = ($ssma_res->[$i] / $n_samples) - $scaled_data[$i];
    $ssma_chisq += (($ssma_res->[$i] - $expected)**2) / $expected;
}

#say join ' ', map {sprintf '%0.6f', $_} @ssm_diffs;
#say '---';
#say join ' ', map {sprintf '%0.6f', $_} @ssma_diffs;

my $ssm_stats = Statistics::Descriptive::Full->new ();
$ssm_stats->add_data (\@ssm_diffs);
say join ' ', 'SSM  ', map {sprintf '% .10f', $_} $ssm_stats->mean, $ssm_stats->standard_deviation, $ssm_stats->min, $ssm_stats->max;

my $ssma_stats = Statistics::Descriptive::Full->new ();
$ssma_stats->add_data (\@ssma_diffs);
say join ' ', 'SSMA ', map {sprintf '% .10f', $_} $ssma_stats->mean, $ssma_stats->standard_deviation, $ssma_stats->min, $ssma_stats->max;

say "SSM  chisq = " . $ssm_chisq;
say "SSMA chisq = " . $ssma_chisq;


__END__

Some raw diffs for $n_samples = 20_000_000:
mean, sd, min, max

SSM   -0.0000000000  0.0000288652 -0.0000941500  0.0000485000
SSMA   0.0000000000  0.0000313555 -0.0000684500  0.0000634000

They are pretty similar.


Chi squared results fall inside the 5-95% confidence intervals
for both methods.
e.g. for df=49:
SSM  chisq = 58.0875966700564
SSMA chisq = 41.4898144299499

