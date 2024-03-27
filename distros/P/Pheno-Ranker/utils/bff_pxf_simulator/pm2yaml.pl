#!/usr/bin/env perl
use strict;
use warnings;
use YAML::XS qw(DumpFile);
use lib ".";

# Assuming Ontologies.pm is in the same directory or in a directory in @INC
use Ontologies
  qw($hpo_array $omim_array $rxnorm_array $ncit_procedures_array $ncit_exposures_array $ethnicity_array);

# Get the 'n' value from command line arguments, default to 5 if not provided
my $n = $ARGV[0] // 5;    # // is the defined-or operator, available from Perl 5.10
my $m = $n - 1;

# Input validation for 'n' to ensure it's a positive integer
die "The argument must be a positive integer." unless $n =~ /^\d+$/ && $n >= 0;

# Convert these arrays into a hash with keys corresponding to your YAML structure
my $data = {
    phenotypicFeatures => [ @$hpo_array[ 0 .. $m ] ],
    diseases           => [ @$omim_array[ 0 .. $m ] ],
    treatments         => [ @$rxnorm_array[ 0 .. $m ] ],
    procedures         => [ @$ncit_procedures_array[ 0 .. $m ] ],
    exposures          => [ @$ncit_exposures_array[ 0 .. $m ] ],
    ethnicity => $ethnicity_array
};

# Write YAML
DumpFile( 'ontologies.yaml', $data );
