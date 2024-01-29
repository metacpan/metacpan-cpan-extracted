#!/usr/bin/env perl
use strict;
use warnings;
use File::Spec::Functions qw(catfile);
use Test::More tests => 2;    # Indicate the number of tests you want to run
use File::Compare;

# The command line script to be tested
my $script = catfile( 'utils', 'csv2pheno_ranker', 'csv2pheno-ranker' );
my $inc = join ' -I', '', @INC; # prepend -I to each path in @INC

############
# TEST 1-2 #
############

{
    # Input file for the command line script, if needed
    my $input_file = catfile( 't', 'example.csv' );

    # The reference files to compare the output with
    my $reference_file   = catfile( 't', 'example_ref.json' );
    my $reference_config = catfile( 't', 'example_config_ref.yaml' );

    # The exppected output files from csv2pheno-ranker 
    my $file   = catfile( 't', 'example.json' );
    my $config = catfile( 't', 'example_config.yaml' );

    # Run the command line script with the input file, and redirect the output to the output_file
    system("$^X $inc $script -i $input_file -sep ';' --set-primary-key --primary-key Id");

    # Compare the output_file and the reference_file
    ok(
        compare( $file, $reference_file ) == 0,
        qq/Output matches the <$reference_file> file/
    );
    ok(
        compare( $config, $reference_config ) == 0,
        qq/Output matches the <$reference_config> file/
    );
    unlink( $file, $config );
}
