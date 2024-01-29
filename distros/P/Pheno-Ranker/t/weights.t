#!/usr/bin/env perl
use strict;
use warnings;
use lib ( './lib', '../lib' );
use Test::Exception tests => 2;
use Pheno::Ranker;

# Define specific error scenarios and their expected messages
my %expected_errors = (
    '1' => 'Expected integer - got string',
    '2' => 'String not allowed - phenotypicFeatures;NCIT:C2985.featureType.id.NCIT:C2985'
);

# Iterate over the defined errors and test that Pheno::Ranker dies as expected
for my $error_code (sort keys %expected_errors) {
    my $ranker = Pheno::Ranker->new(
        {
            reference_file => 't/individuals.json',
            weights_file   => "t/weights_err$error_code.yaml",
            config_file    => undef
        }
    );
    # Test that Pheno::Ranker throws an exception with the expected message
    # NB: Not testing the actual error message itself. Only testing that it dies
    dies_ok { $ranker->run } "Pheno::Ranker dies with the expected error for scenario $error_code: $expected_errors{$error_code}";
}
