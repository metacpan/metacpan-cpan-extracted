use strict;
use warnings;
use Test::More tests => 4;
use Statistics::CaseResampling ':all';
use List::Util qw(sum);

my @sample = qw(20 10 1 5.1 -10. 2.1 5.5);

my $mean = sum(@sample) / @sample;
is_approx(mean(\@sample), $mean, "mean");

my @diffsq = map {($_-$mean)**2} @sample;
my $std_dev = sqrt( sum(@diffsq) / @sample );
my $samp_std_dev = sqrt( sum(@diffsq) / (@sample-1) );

is_approx(sample_standard_deviation($mean, \@sample), $samp_std_dev, "sample_standard_deviation");
is_approx(population_standard_deviation($mean, \@sample), $std_dev, "population_standard_deviation");


is_approx(median(\@sample), 5.1);

sub is_approx {
  ok($_[0]+1e-9 > $_[1] && $_[0]-1e-9 < $_[1], ($_[2] ? $_[2] : ()));
}
