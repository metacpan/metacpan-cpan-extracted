#!/usr/bin/env perl
use strict;
use warnings;
use autodie;
use File::Spec::Functions qw(catfile);
use File::Temp            qw{ tempfile };    # core
use Test::More tests => 2;                   # Indicate the number of tests you want to run
use File::Compare;
use lib ( './lib', '../lib' );

#use Data::Dumper;

##########
# TEST 1 #
##########

use_ok('Pheno::Ranker') or exit;

# Input file for the command line script, if needed
my $input_file = catfile( 't', 'individuals.json' );

##########
# TEST 2 #
##########

# The reference file to compare the output with
my $poi            = '107:week_0_arm_1';
my $reference_file = catfile( 'xt', 'poi', "$poi.json" );
my $new_file       = catfile( 'xt', "$poi.json" );

# The generated output file
my ( undef, $tmp_file ) =
  tempfile( DIR => 't', SUFFIX => ".json", UNLINK => 1 );

my $ranker = Pheno::Ranker->new(
    {
        "age"                       => 0,
        "align"                     => "",
        "align_basename"            => "t/tar_align",
        "append_prefixes"           => [],
        "config_file"               => undef,
        "debug"                     => undef,
        "exclude_terms"             => [],
        "export"                    => undef,
        "hpo_file"                  => undef,
        "include_terms"             => [],
        "include_hpo_ascendants"    => undef,
        "log"                       => "",
        "max_matrix_records_in_ram" => undef,
        "max_number_vars"           => undef,
        "max_out"                   => 36,
        "out_file"                  => $tmp_file,
        "patients_of_interest"      => [$poi],
        "poi_out_dir"               => 'xt',
        "reference_files"           => [$input_file],
        "sort_by"                   => undef,
        "similarity_metric_cohort"  => undef,
        "target_file"               => undef,
        "verbose"                   => undef,
        "weights_file"              => undef
    }
);

# Method 'run'
$ranker->run;

ok(
    compare( $new_file, $reference_file ) == 0,
    qq/Output matches the <$reference_file> file/
);
unlink($new_file)

