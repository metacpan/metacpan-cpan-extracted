use 5.010;
use strict;
use warnings;

use rlib;
use Statistics::Descriptive::PDL::SampleWeighted;

my (@data, @wts);

for my $i (0..100000) {
    push @data, int (rand() * 100);
    push @wts, int (rand() * 10);
}

my $stats = Statistics::Descriptive::PDL::SampleWeighted->new;
$stats->add_data (\@data, \@wts);

my @methods = qw /mean standard_deviation kurtosis skewness mode/;

my %results;
for my $i (0..1000) {
    foreach my $method (@methods) {
        $results{$method} = $stats->$method;
        #say "$method $results{$method}";
    }
}
