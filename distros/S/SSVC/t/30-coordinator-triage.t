#!perl

use strict;
use warnings;

use Test::More;

use_ok('SSVC::CoordinatorTriage');

while (my $line = <DATA>) {

    chomp($line);
    next unless length $line;
    next if $line =~ /^#/;

    my (
        $report_public,        $supplier_contacted,  $report_credibility,
        $supplier_cardinality, $supplier_engagement, $automatable,
        $value_density,        $safety_impact,       $expected
    ) = split /\|/, $line;

    my $ssvc = eval {
        SSVC::CoordinatorTriage->new(
            report_public        => $report_public,
            supplier_contacted   => $supplier_contacted,
            report_credibility   => $report_credibility,
            supplier_cardinality => $supplier_cardinality,
            supplier_engagement  => $supplier_engagement,
            automatable          => $automatable,
            value_density        => $value_density,
            safety_impact        => $safety_impact,
        );
    };

    fail($@) if $@;

    is($ssvc->decision, $expected, $line) or diag explain $ssvc;

}

done_testing();

__DATA__
# https://github.com/CERTCC/SSVC/blob/main/data/csv/ssvc/utility_1_0_0.csv
# https://github.com/CERTCC/SSVC/blob/main/data/csv/ssvc/coordinator_triage_1_0_0.csv
yes|no|not_credible|one|active|no|diffuse|negligible|decline
no|no|not_credible|one|active|no|diffuse|negligible|decline
yes|yes|not_credible|one|active|no|diffuse|negligible|decline
yes|no|credible|one|active|no|diffuse|negligible|decline
yes|no|not_credible|multiple|active|no|diffuse|negligible|decline
yes|no|not_credible|one|unresponsive|no|diffuse|negligible|decline
yes|no|not_credible|one|active|no|concentrated|negligible|decline
yes|no|not_credible|one|active|no|diffuse|marginal|decline
no|yes|not_credible|one|active|no|diffuse|negligible|decline
no|no|credible|one|active|no|diffuse|negligible|decline
yes|yes|credible|one|active|no|diffuse|negligible|decline
no|no|not_credible|multiple|active|no|diffuse|negligible|decline
yes|yes|not_credible|multiple|active|no|diffuse|negligible|decline
yes|no|credible|multiple|active|no|diffuse|negligible|decline
no|no|not_credible|one|unresponsive|no|diffuse|negligible|decline
yes|yes|not_credible|one|unresponsive|no|diffuse|negligible|decline
yes|no|credible|one|unresponsive|no|diffuse|negligible|decline
yes|no|not_credible|multiple|unresponsive|no|diffuse|negligible|decline
no|no|not_credible|one|active|no|concentrated|negligible|decline
yes|yes|not_credible|one|active|no|concentrated|negligible|decline
yes|no|credible|one|active|no|concentrated|negligible|decline
yes|no|not_credible|multiple|active|no|concentrated|negligible|decline
yes|no|not_credible|one|unresponsive|no|concentrated|negligible|decline
yes|no|not_credible|one|active|yes|concentrated|negligible|decline
no|no|not_credible|one|active|no|diffuse|marginal|decline
yes|yes|not_credible|one|active|no|diffuse|marginal|decline
yes|no|credible|one|active|no|diffuse|marginal|decline
yes|no|not_credible|multiple|active|no|diffuse|marginal|decline
yes|no|not_credible|one|unresponsive|no|diffuse|marginal|decline
yes|no|not_credible|one|active|no|concentrated|marginal|decline
no|yes|credible|one|active|no|diffuse|negligible|decline
no|yes|not_credible|multiple|active|no|diffuse|negligible|decline
no|no|credible|multiple|active|no|diffuse|negligible|decline
yes|yes|credible|multiple|active|no|diffuse|negligible|decline
no|yes|not_credible|one|unresponsive|no|diffuse|negligible|decline
no|no|credible|one|unresponsive|no|diffuse|negligible|decline
yes|yes|credible|one|unresponsive|no|diffuse|negligible|decline
no|no|not_credible|multiple|unresponsive|no|diffuse|negligible|decline
yes|yes|not_credible|multiple|unresponsive|no|diffuse|negligible|decline
yes|no|credible|multiple|unresponsive|no|diffuse|negligible|decline
no|yes|not_credible|one|active|no|concentrated|negligible|decline
no|no|credible|one|active|no|concentrated|negligible|decline
yes|yes|credible|one|active|no|concentrated|negligible|decline
no|no|not_credible|multiple|active|no|concentrated|negligible|decline
yes|yes|not_credible|multiple|active|no|concentrated|negligible|decline
yes|no|credible|multiple|active|no|concentrated|negligible|decline
no|no|not_credible|one|unresponsive|no|concentrated|negligible|decline
yes|yes|not_credible|one|unresponsive|no|concentrated|negligible|decline
yes|no|credible|one|unresponsive|no|concentrated|negligible|decline
yes|no|not_credible|multiple|unresponsive|no|concentrated|negligible|decline
no|no|not_credible|one|active|yes|concentrated|negligible|decline
yes|yes|not_credible|one|active|yes|concentrated|negligible|decline
yes|no|credible|one|active|yes|concentrated|negligible|decline
yes|no|not_credible|multiple|active|yes|concentrated|negligible|decline
yes|no|not_credible|one|unresponsive|yes|concentrated|negligible|decline
no|yes|not_credible|one|active|no|diffuse|marginal|decline
no|no|credible|one|active|no|diffuse|marginal|decline
yes|yes|credible|one|active|no|diffuse|marginal|decline
no|no|not_credible|multiple|active|no|diffuse|marginal|decline
yes|yes|not_credible|multiple|active|no|diffuse|marginal|decline
yes|no|credible|multiple|active|no|diffuse|marginal|decline
no|no|not_credible|one|unresponsive|no|diffuse|marginal|decline
yes|yes|not_credible|one|unresponsive|no|diffuse|marginal|decline
yes|no|credible|one|unresponsive|no|diffuse|marginal|decline
yes|no|not_credible|multiple|unresponsive|no|diffuse|marginal|decline
no|no|not_credible|one|active|no|concentrated|marginal|decline
yes|yes|not_credible|one|active|no|concentrated|marginal|decline
yes|no|credible|one|active|no|concentrated|marginal|decline
yes|no|not_credible|multiple|active|no|concentrated|marginal|decline
yes|no|not_credible|one|unresponsive|no|concentrated|marginal|decline
yes|no|not_credible|one|active|yes|concentrated|marginal|decline
no|yes|credible|multiple|active|no|diffuse|negligible|decline
no|yes|credible|one|unresponsive|no|diffuse|negligible|track
no|yes|not_credible|multiple|unresponsive|no|diffuse|negligible|decline
no|no|credible|multiple|unresponsive|no|diffuse|negligible|decline
yes|yes|credible|multiple|unresponsive|no|diffuse|negligible|decline
no|yes|credible|one|active|no|concentrated|negligible|decline
no|yes|not_credible|multiple|active|no|concentrated|negligible|decline
no|no|credible|multiple|active|no|concentrated|negligible|decline
yes|yes|credible|multiple|active|no|concentrated|negligible|decline
no|yes|not_credible|one|unresponsive|no|concentrated|negligible|decline
no|no|credible|one|unresponsive|no|concentrated|negligible|decline
yes|yes|credible|one|unresponsive|no|concentrated|negligible|decline
no|no|not_credible|multiple|unresponsive|no|concentrated|negligible|decline
yes|yes|not_credible|multiple|unresponsive|no|concentrated|negligible|decline
yes|no|credible|multiple|unresponsive|no|concentrated|negligible|decline
no|yes|not_credible|one|active|yes|concentrated|negligible|decline
no|no|credible|one|active|yes|concentrated|negligible|decline
yes|yes|credible|one|active|yes|concentrated|negligible|decline
no|no|not_credible|multiple|active|yes|concentrated|negligible|decline
yes|yes|not_credible|multiple|active|yes|concentrated|negligible|decline
yes|no|credible|multiple|active|yes|concentrated|negligible|decline
no|no|not_credible|one|unresponsive|yes|concentrated|negligible|decline
yes|yes|not_credible|one|unresponsive|yes|concentrated|negligible|decline
yes|no|credible|one|unresponsive|yes|concentrated|negligible|decline
yes|no|not_credible|multiple|unresponsive|yes|concentrated|negligible|decline
no|yes|credible|one|active|no|diffuse|marginal|decline
no|yes|not_credible|multiple|active|no|diffuse|marginal|track
no|no|credible|multiple|active|no|diffuse|marginal|decline
yes|yes|credible|multiple|active|no|diffuse|marginal|decline
no|yes|not_credible|one|unresponsive|no|diffuse|marginal|decline
no|no|credible|one|unresponsive|no|diffuse|marginal|decline
yes|yes|credible|one|unresponsive|no|diffuse|marginal|decline
no|no|not_credible|multiple|unresponsive|no|diffuse|marginal|decline
yes|yes|not_credible|multiple|unresponsive|no|diffuse|marginal|decline
yes|no|credible|multiple|unresponsive|no|diffuse|marginal|decline
no|yes|not_credible|one|active|no|concentrated|marginal|track
no|no|credible|one|active|no|concentrated|marginal|decline
yes|yes|credible|one|active|no|concentrated|marginal|decline
no|no|not_credible|multiple|active|no|concentrated|marginal|decline
yes|yes|not_credible|multiple|active|no|concentrated|marginal|decline
yes|no|credible|multiple|active|no|concentrated|marginal|decline
no|no|not_credible|one|unresponsive|no|concentrated|marginal|decline
yes|yes|not_credible|one|unresponsive|no|concentrated|marginal|decline
yes|no|credible|one|unresponsive|no|concentrated|marginal|decline
yes|no|not_credible|multiple|unresponsive|no|concentrated|marginal|decline
no|no|not_credible|one|active|yes|concentrated|marginal|decline
yes|yes|not_credible|one|active|yes|concentrated|marginal|decline
yes|no|credible|one|active|yes|concentrated|marginal|decline
yes|no|not_credible|multiple|active|yes|concentrated|marginal|coordinate
yes|no|not_credible|one|unresponsive|yes|concentrated|marginal|decline
no|yes|credible|multiple|unresponsive|no|diffuse|negligible|coordinate
no|yes|credible|multiple|active|no|concentrated|negligible|decline
no|yes|credible|one|unresponsive|no|concentrated|negligible|coordinate
no|yes|not_credible|multiple|unresponsive|no|concentrated|negligible|decline
no|no|credible|multiple|unresponsive|no|concentrated|negligible|decline
yes|yes|credible|multiple|unresponsive|no|concentrated|negligible|decline
no|yes|credible|one|active|yes|concentrated|negligible|decline
no|yes|not_credible|multiple|active|yes|concentrated|negligible|track
no|no|credible|multiple|active|yes|concentrated|negligible|decline
yes|yes|credible|multiple|active|yes|concentrated|negligible|decline
no|yes|not_credible|one|unresponsive|yes|concentrated|negligible|decline
no|no|credible|one|unresponsive|yes|concentrated|negligible|decline
yes|yes|credible|one|unresponsive|yes|concentrated|negligible|decline
no|no|not_credible|multiple|unresponsive|yes|concentrated|negligible|decline
yes|yes|not_credible|multiple|unresponsive|yes|concentrated|negligible|decline
yes|no|credible|multiple|unresponsive|yes|concentrated|negligible|decline
no|yes|credible|multiple|active|no|diffuse|marginal|track
no|yes|credible|one|unresponsive|no|diffuse|marginal|coordinate
no|yes|not_credible|multiple|unresponsive|no|diffuse|marginal|track
no|no|credible|multiple|unresponsive|no|diffuse|marginal|decline
yes|yes|credible|multiple|unresponsive|no|diffuse|marginal|decline
no|yes|credible|one|active|no|concentrated|marginal|track
no|yes|not_credible|multiple|active|no|concentrated|marginal|track
no|no|credible|multiple|active|no|concentrated|marginal|decline
yes|yes|credible|multiple|active|no|concentrated|marginal|decline
no|yes|not_credible|one|unresponsive|no|concentrated|marginal|track
no|no|credible|one|unresponsive|no|concentrated|marginal|decline
yes|yes|credible|one|unresponsive|no|concentrated|marginal|decline
no|no|not_credible|multiple|unresponsive|no|concentrated|marginal|decline
yes|yes|not_credible|multiple|unresponsive|no|concentrated|marginal|decline
yes|no|credible|multiple|unresponsive|no|concentrated|marginal|decline
no|yes|not_credible|one|active|yes|concentrated|marginal|track
no|no|credible|one|active|yes|concentrated|marginal|decline
yes|yes|credible|one|active|yes|concentrated|marginal|decline
no|no|not_credible|multiple|active|yes|concentrated|marginal|coordinate
yes|yes|not_credible|multiple|active|yes|concentrated|marginal|coordinate
yes|no|credible|multiple|active|yes|concentrated|marginal|coordinate
no|no|not_credible|one|unresponsive|yes|concentrated|marginal|decline
yes|yes|not_credible|one|unresponsive|yes|concentrated|marginal|decline
yes|no|credible|one|unresponsive|yes|concentrated|marginal|decline
yes|no|not_credible|multiple|unresponsive|yes|concentrated|marginal|coordinate
no|yes|credible|multiple|unresponsive|no|concentrated|negligible|coordinate
no|yes|credible|multiple|active|yes|concentrated|negligible|coordinate
no|yes|credible|one|unresponsive|yes|concentrated|negligible|coordinate
no|yes|not_credible|multiple|unresponsive|yes|concentrated|negligible|track
no|no|credible|multiple|unresponsive|yes|concentrated|negligible|decline
yes|yes|credible|multiple|unresponsive|yes|concentrated|negligible|decline
no|yes|credible|multiple|unresponsive|no|diffuse|marginal|coordinate
no|yes|credible|multiple|active|no|concentrated|marginal|track
no|yes|credible|one|unresponsive|no|concentrated|marginal|coordinate
no|yes|not_credible|multiple|unresponsive|no|concentrated|marginal|track
no|no|credible|multiple|unresponsive|no|concentrated|marginal|decline
yes|yes|credible|multiple|unresponsive|no|concentrated|marginal|decline
no|yes|credible|one|active|yes|concentrated|marginal|track
no|yes|not_credible|multiple|active|yes|concentrated|marginal|coordinate
no|no|credible|multiple|active|yes|concentrated|marginal|coordinate
yes|yes|credible|multiple|active|yes|concentrated|marginal|coordinate
no|yes|not_credible|one|unresponsive|yes|concentrated|marginal|track
no|no|credible|one|unresponsive|yes|concentrated|marginal|decline
yes|yes|credible|one|unresponsive|yes|concentrated|marginal|decline
no|no|not_credible|multiple|unresponsive|yes|concentrated|marginal|coordinate
yes|yes|not_credible|multiple|unresponsive|yes|concentrated|marginal|coordinate
yes|no|credible|multiple|unresponsive|yes|concentrated|marginal|coordinate
no|yes|credible|multiple|unresponsive|yes|concentrated|negligible|coordinate
no|yes|credible|multiple|unresponsive|no|concentrated|marginal|coordinate
no|yes|credible|multiple|active|yes|concentrated|marginal|coordinate
no|yes|credible|one|unresponsive|yes|concentrated|marginal|coordinate
no|yes|not_credible|multiple|unresponsive|yes|concentrated|marginal|coordinate
no|no|credible|multiple|unresponsive|yes|concentrated|marginal|coordinate
yes|yes|credible|multiple|unresponsive|yes|concentrated|marginal|coordinate
no|yes|credible|multiple|unresponsive|yes|concentrated|marginal|coordinate
