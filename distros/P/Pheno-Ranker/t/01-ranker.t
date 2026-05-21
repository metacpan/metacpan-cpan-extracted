#!/usr/bin/env perl
use strict;
use warnings;
use autodie;
use File::Spec::Functions qw(catfile);
use File::Temp            qw{ tempdir };    # core
use Test::More tests => 14;                  # Indicate the number of tests you want to run
use File::Compare;
use List::MoreUtils qw(pairwise);
use lib qw(./lib ../lib t/lib);
use Test::PhenoRanker qw(fixture temp_output_file);

#use Data::Dumper;

use constant IS_WINDOWS => ( $^O eq 'MSWin32' || $^O eq 'cygwin' ) ? 1 : 0;

##########
# TEST 1 #
##########

use_ok('Pheno::Ranker') or exit;

# Input file for the command line script, if needed
my $input_file = fixture('individuals.json');

SKIP: {
    # Linux commands don't run on windows
    skip qq{Sipping WIn32 tests}, 13 if IS_WINDOWS;

    ##########
    # TEST 2 #
    ##########

    {
        # The reference file to compare the output with
        my $reference_file = fixture('matrix_ref.txt');

        # The generated output file
        my $tmp_file = temp_output_file();

        my $ranker = Pheno::Ranker->new(
            {
                "age"             => 0,
                "align"           => "",
                "align_basename"  => temp_align_basename(),
                "append_prefixes" => [],
                "exclude_terms"             => [],
                "include_terms"             => [],
                "log"                       => "",
                "max_out"                   => 36,
                "out_file"                  => $tmp_file,
                "patients_of_interest"      => [],
                "reference_files"           => [$input_file],
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
    my $patient_file = fixture('patient.json');
    my $weights_file = fixture('weights.yaml');

    {
        my $ranker = Pheno::Ranker->new(
            {
                "age"                       => 0,
                "align"                     => "",
                "align_basename"            => temp_align_basename(),
                "append_prefixes"           => [],
                "exclude_terms"             => [],
                "include_terms"             => [],
                "log"                       => "",
                "max_out"                   => 36,
                "out_file"                  => temp_output_file( suffix => '.txt' ),
                "patients_of_interest"      => [],
                "reference_files"           => [$input_file],
                "target_file"               => $patient_file,
                "weights_file"              => $weights_file
            }
        );

        # Method 'run'
        $ranker->run;

        # *** --align ****
        # alignment.txt
        # *** IMPORTANT ****
        # We only compare NUMERIC results, not ASCII alignment!!!
        my $align_file;
        my $reference_file = fixture('ref_align.csv');
        $align_file = $ranker->align_basename . '.csv';
        ok(
            compare_sorted_files( $align_file, $reference_file ),
            qq/<$align_file> matches the <$reference_file> file/

        );
        unlink $align_file;

        # alignment.target.csv
        $reference_file = fixture('ref_align.target.csv');
        $align_file     = $ranker->align_basename . '.target.csv';
        ok(
            compare_sorted_files( $align_file, $reference_file ),
            qq/<$align_file> matches the <$reference_file> file/
        );
        unlink $align_file;

        # alignment.txt
        $reference_file = fixture('ref_align.txt');
        $align_file     = $ranker->align_basename . '.txt';
        ok(
            compare_sorted_files( $align_file, $reference_file ),
            qq/<$align_file> matches the <$reference_file> file/

        );
        unlink $align_file;
    }

    ##########
    # TEST 6 #
    ##########
    # Inter-cohort

    {
        # Input file 2
        my $other_input_file = fixture('patient.json');

        # The reference file to compare the output with
        my $reference_file = fixture('inter_cohort_matrix_ref.txt');

        # The generated output file
        my $tmp_file = temp_output_file();

        my $ranker = Pheno::Ranker->new(
            {
                "age"             => 0,
                "align"           => "",
                "align_basename"  => temp_align_basename(),
                "append_prefixes" => [ 'FOO', 'BAR' ],
                "exclude_terms"             => [],
                "include_terms"             => [],
                "log"                       => "",
                "max_out"                   => 36,
                "out_file"                  => $tmp_file,
                "patients_of_interest"      => [],
                "reference_files" => [ $input_file, $other_input_file ],
            }
        );

        # Method 'run'
        $ranker->run;

        # Compare the output_file and the reference_file
        ok(
            compare( $tmp_file, $reference_file ) == 0,
            qq/Output matches the <$reference_file> file/
        );
    }

    ##########
    # TEST 7 #
    ##########
    # Jaccard

    {
        # The reference file to compare the output with
        my $reference_file = fixture('matrix_ref_jaccard.txt');

        # The generated output file
        my $tmp_file = temp_output_file();

        my $ranker = Pheno::Ranker->new(
            {
                "age"             => 0,
                "align"           => "",
                "align_basename"  => temp_align_basename(),
                "append_prefixes" => [],
                "exclude_terms"             => [],
                "include_terms"             => [],
                "log"                       => "",
                "max_out"                   => 36,
                "out_file"                  => $tmp_file,
                "patients_of_interest"      => [],
                "reference_files"           => [$input_file],
                "similarity_metric_cohort"  => 'jaccard',
            }
        );

        # Method 'run'
        $ranker->run;

        # Compare the output_file and the reference_file
        ok(
            compare( $tmp_file, $reference_file ) == 0,
            qq/Output matches the <$reference_file> file/
        );
    }

    ##########
    # TEST 8 #
    ##########
    # weight 0

    {
        # The reference file to compare the output with
        my $reference_file = fixture('matrix_ref_weights_zero.txt');
        my $weights_file   = fixture('weights_zero.yaml');

        # The generated output file
        my $tmp_file = temp_output_file();

        my $ranker = Pheno::Ranker->new(
            {
                "age"             => 0,
                "align"           => "",
                "align_basename"  => temp_align_basename(),
                "append_prefixes" => [],
                "exclude_terms"             => [],
                "include_terms"             => [],
                "log"                       => "",
                "max_out"                   => 36,
                "out_file"                  => $tmp_file,
                "patients_of_interest"      => [],
                "reference_files"           => [$input_file],
                "weights_file"              => $weights_file
            }
        );

        # Method 'run'
        $ranker->run;

        # Compare the output_file and the reference_file
        ok(
            compare( $tmp_file, $reference_file ) == 0,
            qq/Output matches the <$reference_file> file/
        );
    }

    ##########
    # TEST 9 #
    ##########
    # interpretations

    {
        my $input_file = fixture('interpretations_pxf.json');

        # The reference file to compare the output with
        my $reference_file =
          fixture('matrix_ref_interpretations_pxf.txt');

        # The generated output file
        my $tmp_file = temp_output_file();

        my $ranker = Pheno::Ranker->new(
            {
                "age"             => 0,
                "align"           => "",
                "align_basename"  => temp_align_basename(),
                "append_prefixes" => [],
                "exclude_terms"             => [],
                "include_terms"             => [],
                "log"                       => "",
                "max_out"                   => 36,
                "out_file"                  => $tmp_file,
                "patients_of_interest"      => [],
                "reference_files"           => [$input_file],
            }
        );

        # Method 'run'
        $ranker->run;

        # Compare the output_file and the reference_file
        ok(
            compare( $tmp_file, $reference_file ) == 0,
            qq/Output matches the <$reference_file> file/
        );
    }

    ##########
    # TEST 10 #
    ##########
    # Test for rank.txt by comparing REFERENCE(ID) column

    {
        # The reference rank.txt file
        my $reference_rank_file = fixture('rank.txt');
        my $target_file         = fixture('patient.json');

        # The generated output rank.txt file
        my $generated_rank_file = temp_output_file( suffix => '.txt' );

        my $ranker = Pheno::Ranker->new(
            {
                "age"             => 0,
                "align"           => "",
                "align_basename"  => temp_align_basename(),
                "append_prefixes" => [],
                "exclude_terms"             => [],
                "include_terms"             => [],
                "log"                       => "",
                "max_out"                   => 36,
                "out_file"                  => $generated_rank_file,
                "patients_of_interest"      => [],
                "reference_files"           => [$input_file],          # Adjust if necessary
                "target_file"               => $target_file,
            }
        );

        # Method 'run'
        $ranker->run;

        # Hardcoded reference IDs from rank.txt
        my @expected_ids = (
            '107:week_0_arm_1',  '125:week_0_arm_1',
            '275:week_0_arm_1',  '215:week_0_arm_1',
            '305:week_0_arm_1',  '365:week_0_arm_1',
            '107:week_14_arm_1', '125:week_2_arm_1',
            '527:week_14_arm_1', '125:week_14_arm_1',
            '527:week_2_arm_1',  '125:week_26_arm_1',
            '107:week_2_arm_1',  '527:week_0_arm_1',
            '365:week_2_arm_1',  '275:week_2_arm_1',
            '365:week_14_arm_1', '305:week_26_arm_1',
            '215:week_26_arm_1', '215:week_2_arm_1',
            '215:week_14_arm_1', '257:week_0_arm_1',
            '365:week_26_arm_1', '275:week_14_arm_1',
            '527:week_26_arm_1', '215:week_78_arm_1',
            '125:week_78_arm_1', '527:week_52_arm_1',
            '125:week_52_arm_1', '365:week_52_arm_1',
            '305:week_52_arm_1', '257:week_14_arm_1',
            '257:week_2_arm_1',  '215:week_52_arm_1',
            '257:week_26_arm_1', '275:week_52_arm_1',
        );

        # Extract REFERENCE(ID)s from generated rank.txt
        my @generated_ids = extract_reference_ids($generated_rank_file);

        # Compare the two arrays as multisets
        my %expected_count;
        $expected_count{$_}++ for @expected_ids;

        my %generated_count;
        $generated_count{$_}++ for @generated_ids;

        my $pass = 1;

        foreach my $id ( keys %expected_count ) {
            if ( !exists $generated_count{$id} ) {
                diag("ID '$id' is missing in the generated output.");
                $pass = 0;
            }
            elsif ( $expected_count{$id} != $generated_count{$id} ) {
                diag(
"ID '$id' has count $expected_count{$id} in reference vs $generated_count{$id} in output."
                );
                $pass = 0;
            }
        }

        foreach my $id ( keys %generated_count ) {
            if ( !exists $expected_count{$id} ) {
                diag("ID '$id' is extra in the generated output.");
                $pass = 0;
            }
        }

        ok( $pass,
qq/<$generated_rank_file> matches the REFERENCE(ID) in <$reference_rank_file>/
        );
    }

    ###########
    # TEST 11 #
    ###########

    {
        # The reference file to compare the output with
        my $input_file     = fixture('pxf_excluded_true.json');
        my $reference_file = fixture('pxf_excluded_true_matrix.txt');

        # The generated output file
        my $tmp_file = temp_output_file();

        my $ranker = Pheno::Ranker->new(
            {
                "age"             => 0,
                "align"           => "",
                "align_basename"  => temp_align_basename(),
                "append_prefixes" => [],
                "exclude_terms"                      => [],
                "include_terms"                      => [],
                "log"                                => "",
                "max_out"                            => 36,
                "out_file"                           => $tmp_file,
                "patients_of_interest"               => [],
                "reference_files"                    => [$input_file],
                "retain_excluded_phenotypicFeatures" => 1,
            }
        );

        # Method 'run'
        $ranker->run;

        # Compare the output_file and the reference_file
        ok(
            compare( $tmp_file, $reference_file ) == 0,
            qq/Output matches the <$reference_file> file/
        );
    }

    ###########
    # TEST 12 #
    ###########
    # --prp

    {
        # The reference file to compare the output with
        my $reference_file = fixture('matrix_ref.txt');

        # The generated output file
        my $tmp_file = temp_output_file();

        my $ranker = Pheno::Ranker->new(
            {
                "age"             => 0,
                "align"           => "",
                "align_basename"  => temp_align_basename(),
                "append_prefixes" => [],
                "glob_hash_file"  => fixture('export.glob_hash.json'),
                "ref_hash_file"   => fixture('export.ref_hash.json'),
                "ref_binary_hash_file" => fixture('export.ref_binary_hash.json'),
                "coverage_stats_file" => fixture('export.ref_binary_hash.json'),
                "exclude_terms"             => [],
                "include_terms"             => [],
                "log"                       => "",
                "max_out"                   => 36,
                "out_file"                  => $tmp_file,
                "patients_of_interest"      => [],
            }
        );

        # Method 'run'
        $ranker->run;

        # Compare the output_file and the reference_file
        ok(
            compare( $tmp_file, $reference_file ) == 0,
            qq/Output matches the <$reference_file> file/
        );
    }

###########
    # TEST 13 #
###########

    {
        # The reference file to compare the output with
        my $input_file     = fixture('individuals.json.gz');
        my $reference_file = fixture('matrix_ref.txt');

        # The generated output file
        my $tmp_file = temp_output_file();

        my $ranker = Pheno::Ranker->new(
            {
                "age"             => 0,
                "align"           => "",
                "align_basename"  => temp_align_basename(),
                "append_prefixes" => [],
                "exclude_terms"             => [],
                "include_terms"             => [],
                "log"                       => "",
                "max_out"                   => 36,
                "out_file"                  => $tmp_file,
                "patients_of_interest"      => [],
                "reference_files"           => [$input_file],
            }
        );

        # Method 'run'
        $ranker->run;

        # Compare the output_file and the reference_file
        ok(
            compare( $tmp_file, $reference_file ) == 0,
            qq/Output matches the <$reference_file> file/
        );
    }

###########
    # TEST 13 #
###########
    # max_matrix_records_in_ram

    {
        # The reference file to compare the output with
        my $input_file     = fixture('individuals.json.gz');
        my $reference_file = fixture('matrix_ref.txt');

        # The generated output file
        my $tmp_file = temp_output_file();

        my $ranker = Pheno::Ranker->new(
            {
                "age"             => 0,
                "align"           => "",
                "align_basename"  => temp_align_basename(),
                "append_prefixes" => [],
                "exclude_terms"             => [],
                "include_terms"             => [],
                "log"                       => "",
                "max_matrix_records_in_ram" => 500,
                "max_out"                   => 36,
                "out_file"                  => $tmp_file,
                "patients_of_interest"      => [],
                "reference_files"           => [$input_file],
            }
        );

        # Method 'run'
        $ranker->run;

        # Compare the output_file and the reference_file
        ok(
            compare( $tmp_file, $reference_file ) == 0,
            qq/Output matches the <$reference_file> file/
        );
    }

}

# Subroutine to extract REFERENCE(ID) from a rank.txt file
sub extract_reference_ids {
    my ($file) = @_;
    open my $fh, '<', $file;

    my @ids;
    while ( my $line = <$fh> ) {
        chomp $line;
        next if $line =~ /^RANK\s+/;    # Skip header line
        next if $line =~ /^\s*$/;       # Skip empty lines

        my @columns = split /\s+/, $line;
        if ( @columns >= 2 ) {
            push @ids, $columns[1];
        }
    }

    close $fh;
    return @ids;
}

sub temp_align_basename {
    return catfile( tempdir( CLEANUP => 1 ), 'tar_align' );
}

sub compare_sorted_files {
    my ( $file1, $file2 ) = @_;

    open my $fh1, '<', $file1;
    open my $fh2, '<', $file2;

    my @lines1 = sort grep { $_ !~ /BFF/ } <$fh1>;
    my @lines2 = sort grep { $_ !~ /BFF/ } <$fh2>;

    close $fh1;
    close $fh2;

    # Compare arrays directly
    return scalar @lines1 == scalar @lines2 && pairwise { $a eq $b } @lines1,
      @lines2;
}
