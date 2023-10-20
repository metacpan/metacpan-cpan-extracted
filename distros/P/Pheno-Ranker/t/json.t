#!/usr/bin/env perl
use strict;
use warnings;
use File::Spec::Functions qw(catfile);
use File::Temp qw{ tempfile };    # core
use Test::More tests => 4;        # Indicate the number of tests you want to run
use File::Compare;
use lib ( './lib', '../lib' );
use Pheno::Ranker;

my $data = {
    "age"                    => 0,
    "align"                  => undef,
    "align_basename"         => "alignment",
    "append_prefixes"        => [],
    "cli"                    => undef,
    "debug"                  => undef,
    "exclude_terms"          => [],
    "export"                 => undef,
    "hpo_file"               => undef,
    "include_hpo_ascendants" => undef,
    "include_terms"          => [],
    "log"                    => "",
    "max_number_var"         => undef,
    "max_out"                => 36,
    "patients_of_interest"   => [],
    "poi_out_dir"            => undef,
    "sort_by"                => undef,
    "target_file"            => undef,
    "verbose"                => undef,
    "weights_file"           => undef
};

##########
# TEST 1 #
##########

{
    # Input file for the command line script, if needed
    my $input_file = catfile( 't', 'movies.json' );

    # The reference file to compare the output with
    my $reference_file = catfile( 't', 'ref_movies_matrix.txt' );

    my $config = catfile( 't', 'movies_config.yaml' );

    # The generated output file
    my ( undef, $tmp_file ) =
      tempfile( DIR => 't', SUFFIX => ".json", UNLINK => 1 );

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
    my $reference_file = catfile( 't', 'ref_movies_include_matrix.txt' );

    # The generated output file
    my ( undef, $tmp_file ) =
      tempfile( DIR => 't', SUFFIX => ".json", UNLINK => 1 );

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
    my $reference_file = catfile( 't', 'ref_movies_weights_matrix.txt' );
    my $weights        = catfile( 't', 'movies_weights.yaml' );

    # The generated output file
    my ( undef, $tmp_file ) =
      tempfile( DIR => 't', SUFFIX => ".json", UNLINK => 1 );

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
    my $input_file = catfile( 't', 'cars.json' );

    # The reference file to compare the output with
    my $reference_file = catfile( 't', 'cars_matrix.txt' );

    my $config = catfile( 't', 'cars_config.yaml' );

    # The generated output file
    my ( undef, $tmp_file ) =
      tempfile( DIR => 't', SUFFIX => ".json", UNLINK => 1 );

    # Update valules
    $data->{out_file}        = $tmp_file;
    $data->{config_file}     = $config;
    $data->{weights_file}    = undef;
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

