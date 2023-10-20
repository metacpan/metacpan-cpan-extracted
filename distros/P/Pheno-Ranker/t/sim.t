#!/usr/bin/env perl
use strict;
use warnings;
use File::Spec::Functions qw(catfile);
use File::Temp qw{ tempfile };    # core
use Test::More tests => 3;        # Indicate the number of tests you want to run
use File::Compare;

# The command line script to be tested
my $script = catfile( 'utils', 'bff_pxf_simulator', 'bff-pxf-simulator' );
my $inc = join ' -I', '', @INC; # prepend -I to each path in @INC

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
"$^X $inc $script -n 100 -f bff -diseases 10 -max-diseases-pool 10 -phenotypicFeatures 10 -max-phenotypicFeatures-pool 10 -treatments 10 --max-treatments-pool 10 --random-seed 12345 -o $tmp_file"
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
    my $reference_file = catfile( 't', 'individuals_random_1000.json' );

    # The generated output file
    my ( undef, $tmp_file ) =
      tempfile( DIR => 't', SUFFIX => ".json", UNLINK => 1 );

    # Run the command line script with the input file, and redirect the output to the output_file
    system(
"$^X $script -n 1000 -f bff -diseases 10 -max-diseases-pool 10 -phenotypicFeatures 10 -max-phenotypicFeatures-pool 10 -treatments 10 --max-treatments-pool 10 --random-seed 12345 -o $tmp_file"
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
"$^X $script -n 100 -f bff -external-ontologies $ont_file -diseases 1 -max-diseases-pool 1 -phenotypicFeatures 1 -max-phenotypicFeatures-pool 1 -treatments 1 --max-treatments-pool 1 --random-seed 12345 -o $tmp_file"
    );

    # Compare the output_file and the reference_file
    ok(
        compare( $tmp_file, $reference_file ) == 0,
        qq/Output matches the <$reference_file> file/
    );
}
