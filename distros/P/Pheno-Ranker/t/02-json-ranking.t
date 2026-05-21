#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 4;                   # Indicate the number of tests you want to run
use File::Compare;
use lib qw(./lib ../lib t/lib);
use Test::PhenoRanker qw(fixture temp_output_file);
use Pheno::Ranker;

my $data = {
    "age"                       => 0,
    "align_basename"            => "alignment",
    "append_prefixes"           => [],
    "exclude_terms"             => [],
    "include_terms"             => [],
    "log"                       => "",
    "max_out"                   => 36,
    "patients_of_interest"      => [],
};

##########
# TEST 1 #
##########

{
    # Input file for the command line script, if needed
    my $input_file = fixture('movies.json');

    # The reference file to compare the output with
    my $reference_file = fixture('ref_movies_matrix.txt');

    my $config = fixture('movies_config.yaml');

    # The generated output file
    my $tmp_file = temp_output_file();

    # Update valules
    $data->{config_file}     = $config;
    $data->{out_file}        = $tmp_file;
    $data->{reference_files} = [$input_file];

    # Create obj
    my $ranker = Pheno::Ranker->new($data);

    # Method 'run'
    $ranker->run;

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
    my $reference_file = fixture('ref_movies_include_matrix.txt');

    # The generated output file
    my $tmp_file = temp_output_file();

    # Update valules
    $data->{out_file}      = $tmp_file;
    $data->{include_terms} = [qw/country year/];

    # Create obj
    my $ranker = Pheno::Ranker->new($data);

    # Method 'run'
    $ranker->run;

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
    my $reference_file = fixture('ref_movies_weights_matrix.txt');
    my $weights        = fixture('movies_weights.yaml');

    # The generated output file
    my $tmp_file = temp_output_file();

    # Update valules
    $data->{out_file}      = $tmp_file;
    $data->{weights_file}  = $weights;
    $data->{include_terms} = [];

    # Create obj
    my $ranker = Pheno::Ranker->new($data);

    # Method 'run'
    $ranker->run;

    # Compare the output_file and the reference_file
    ok(
        compare( $tmp_file, $reference_file ) == 0,
        qq/Output matches the <$reference_file> file/
    );
}

##########
# TEST 4 #
##########

{
    # Input file for the command line script, if needed
    my $input_file = fixture('cars.json');

    # The reference file to compare the output with
    my $reference_file = fixture('cars_matrix.txt');

    my $config = fixture('cars_config.yaml');

    # The generated output file
    my $tmp_file = temp_output_file();

    # Update valules
    $data->{out_file}        = $tmp_file;
    $data->{config_file}     = $config;
    delete $data->{weights_file};
    $data->{reference_files} = [$input_file];

    # Create obj
    my $ranker = Pheno::Ranker->new($data);

    # Method 'run'
    $ranker->run;

    # Compare the output_file and the reference_file
    ok(
        compare( $tmp_file, $reference_file ) == 0,
        qq/Output matches the <$reference_file> file/
    );
}
