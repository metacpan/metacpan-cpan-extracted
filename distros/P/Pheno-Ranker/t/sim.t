#!/usr/bin/env perl
use strict;
use warnings;
use File::Spec::Functions qw(catfile);
use File::Temp qw{ tempfile };    # core
use Test::More tests => 3;        # Indicate the number of tests you want to run
use File::Compare;

# Seed for srand
my $seed = 123456789;

# The command line script to be tested
my $script = catfile( 'utils', 'bff_pxf_simulator', 'bff-pxf-simulator' );
my $inc    = join ' -I', '', @INC;    # prepend -I to each path in @INC

##########
# TEST 1 #
##########

{
    # The reference file to compare the output with
    my $reference_file = catfile( 't', 'individuals_random_100.json' );

    # The generated output file
    my ( undef, $tmp_file ) =
      tempfile( DIR => 't', SUFFIX => ".json", UNLINK => 1 );

    # Run the command line script with the input file, and redirect the output to the output_file
    system(
"$^X $inc $script -n 100 -f bff -diseases 10 -max-diseases-pool 10 -phenotypicFeatures 10 -max-phenotypicFeatures-pool 10 -treatments 10 --max-treatments-pool 10 -procedures 10 -max-procedures-pool 10 -exposures 10 -max-exposures-pool 10 --random-seed $seed -o $tmp_file"
    );

    # Compare the output_file and the reference_file
    ok(
        compare( $tmp_file, $reference_file ) == 0,
        qq/Output matches the <$reference_file> file/
    );
}

##########
# TEST 2 #
##########

{
    # The reference file to compare the output with
    my $reference_file = catfile( 't', 'pxf_random_100.json' );

    # The generated output file
    my ( undef, $tmp_file ) =
      tempfile( DIR => 't', SUFFIX => ".json", UNLINK => 1 );

    # Run the command line script with the input file, and redirect the output to the output_file
    system(
"$^X $inc $script -n 100 -f pxf -diseases 10 -max-diseases-pool 10 -phenotypicFeatures 10 -max-phenotypicFeatures-pool 10 -treatments 10 --max-treatments-pool 10 -procedures 10 -max-procedures-pool 10 --random-seed $seed -o $tmp_file"
    );

    # Compare the output_file and the reference_file
    ok(
        compare( $tmp_file, $reference_file ) == 0,
        qq/Output matches the <$reference_file> file/
    );
}


##########
# TEST 3 #
##########

{
    # The reference file to compare the output with
    my $reference_file =
      catfile( 't', 'individuals_random_100_ontologies.json' );
    my $ont_file = catfile( 't', 'ontologies.yaml' );

    # The generated output file
    my ( undef, $tmp_file ) =
      tempfile( DIR => 't', SUFFIX => ".json", UNLINK => 1 );

    # Run the command line script with the input file, and redirect the output to the output_file
    system(
"$^X $script -n 100 -f bff --external-ontologies $ont_file -diseases 1 -max-diseases-pool 1 -phenotypicFeatures 1 -max-phenotypicFeatures-pool 1 -treatments 1 -max-treatments-pool 1 --exposures 0 -procedures 0 --random-seed $seed -o $tmp_file"
    );

    ########
    # TODO #
    ########
    # Test 3 usually passes on most CPAN systems tested (90%), but it fails on a few (10% - incl. G. Colab).
    # Unlike tests 1 and 2, Test 3 uses the ontologies.yaml file.
    #
    # The problem seems to be with the rand() function, which generates inconsistent random
    # numbers. This leads to variations in certain fields (like sex, ethnicity) within the
    # ontologies. The exact cause of the failure is still unclear.
    # Note that srand/rand work fine when isolated.

  TODO: {
        local $TODO = 'failures due srand/rand system differences';

        # Compare the output_file and the reference_file
        ok(
            compare( $tmp_file, $reference_file ) == 0,
            qq/Output matches the <$reference_file> file/
        );
    }
}
