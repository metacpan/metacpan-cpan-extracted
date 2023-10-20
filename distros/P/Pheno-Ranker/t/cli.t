#!/usr/bin/env perl
use strict;
use warnings;
use autodie;
use File::Spec::Functions qw(catfile);
use File::Temp qw{ tempfile };    # core
use Test::More tests => 5;        # Indicate the number of tests you want to run
use File::Compare;
use lib ( './lib', '../lib' );

use constant IS_WINDOWS => ( $^O eq 'MSWin32' || $^O eq 'cygwin' ) ? 1 : 0;

##########
# TEST 1 #
##########

use_ok('Pheno::Ranker') or exit;

# Input file for the command line script, if needed
my $input_file = catfile( 't', 'individuals.json' );

SKIP: {
    # Linux commands don't run on windows
    skip qq{Sipping WIn32 tests}, 4 if IS_WINDOWS;

    ##########
    # TEST 2 #
    ##########

    {
        # The reference file to compare the output with
        my $reference_file = catfile( 't', 'matrix_ref.txt' );

        # The generated output file
        my ( undef, $tmp_file ) =
          tempfile( DIR => 't', SUFFIX => ".json", UNLINK => 1 );

        my $ranker = Pheno::Ranker->new(
            {
                "age"                    => 0,
                "align"                  => "",
                "align_basename"         => "t/tar_align",
                "append_prefixes"        => [],
                #"cli"                    => undef,
                "config_file"            => undef,
                "debug"                  => undef,
                "exclude_terms"          => [],
                "export"                 => undef,
                "hpo_file"               => undef,
                "include_hpo_ascendants" => undef,
                "include_terms"          => [],
                "log"                    => "",
                "max_number_var"         => undef,
                "max_out"                => 36,
                "out_file"               => $tmp_file,
                "patients_of_interest"   => [],
                "poi_out_dir"            => undef,
                "reference_files"        => [$input_file],
                "sort_by"                => undef,
                "target_file"            => undef,
                "verbose"                => undef,
                "weights_file"           => undef
            }
        );

        # Method 'run'
        $ranker->run;

        # Run the command line script with the input file, and redirect the output to the output_file
        # *** IMPORTANT ***
        # Tests performed via system("foo") are not read by Devel::Cover
        # my $script = catfile( './bin', 'pheno-ranker' );
        # system("$script -r $input_file -o $tmp_file");

        # Compare the output_file and the reference_file
        ok(
            compare( $tmp_file, $reference_file ) == 0,
            qq/Output matches the <$reference_file> file/
        );
    }

    #############
    # TESTs 3-5 #
    #############

    # This one goes via module to be captured by Devel::Cover
    my $patient_file   = catfile( 't', 'patient.json' );
    my $reference_file = catfile( 't', 'rank_weight_ref_sorted.txt' );
    my $weights_file   = catfile( 't', 'weights.yaml' );

    {
        my $ranker = Pheno::Ranker->new(
            {
                "age"                    => 0,
                "align"                  => "",
                "align_basename"         => "t/tar_align",
                "append_prefixes"        => [],
                "cli"                    => undef,
                "config_file"            => undef,
                "debug"                  => undef,
                "exclude_terms"          => [],
                "export"                 => undef,
                "hpo_file"               => undef,
                "include_hpo_ascendants" => undef,
                "include_terms"          => [],
                "log"                    => "",
                "max_number_var"         => undef,
                "max_out"                => 36,
                "out_file"               => "matrix.txt",
                "patients_of_interest"   => [],
                "poi_out_dir"            => undef,
                "reference_files"        => [$input_file],
                "sort_by"                => undef,
                "target_file"            => $patient_file,
                "verbose"                => undef,
                "weights_file"           => $weights_file
            }
        );

        # Method 'run'
        $ranker->run;

        # *** --align ****
        # alignment.txt
        my $align_file;
        $reference_file = catfile( 't', 'ref_align.csv' );
        $align_file     = catfile( 't', 'tar_align.csv' );
        ok(
            compare_sorted_files( $align_file, $reference_file ),
            qq/<$align_file> matches the <$reference_file> file/

        );
        unlink $align_file;

        # alignment.target.csv
        $reference_file = catfile( 't', 'ref_align.target.csv' );
        $align_file     = catfile( 't', 'tar_align.target.csv' );
        ok(
            compare_sorted_files( $align_file, $reference_file ),
            qq/<$align_file> matches the <$reference_file> file/
        );
        unlink $align_file;

        # alignment.txt
        $reference_file = catfile( 't', 'ref_align.txt' );
        $align_file     = catfile( 't', 'tar_align.txt' );
        ok(
            compare_sorted_files( $align_file, $reference_file ),
            qq/<$align_file> matches the <$reference_file> file/

        );
        unlink $align_file;
    }
}

sub compare_sorted_files {

    my ( $file1, $file2 ) = @_;

    # Step 1: Read the contents of each file into separate arrays
    open my $fh1, '<', $file1;
    open my $fh2, '<', $file2;

    my @lines1 = <$fh1>;
    my @lines2 = <$fh2>;

    close $fh1;
    close $fh2;

    # Step 2: Sort the arrays
    # NB: Getting rid of unwanted lines for sorting
	@lines1 = sort grep { $_ !~ /BFF/ } @lines1;
    @lines2 = sort grep { $_ !~ /BFF/ } @lines2;

    # Step 3: Write the sorted content to temporary files
    my $temp_file1 = catfile( 't', 'temp_file1.txt' );
    my $temp_file2 = catfile( 't', 'temp_file2.txt' );

    open my $tfh1, '>', $temp_file1;
    open my $tfh2, '>', $temp_file2;

    print $tfh1 @lines1;
    print $tfh2 @lines2;

    close $tfh1;
    close $tfh2;

    # Compare
    my $compare_result = compare( $temp_file1, $temp_file2 ) == 0;

    # Cleanup: Remove the temporary files
    unlink( $temp_file1, $temp_file2 );

    return $compare_result;
}
