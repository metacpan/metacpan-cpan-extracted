use strict;
use warnings;
use File::Spec qw();
use FindBin qw($Bin);
use lib "$Bin/lib";
use Perl::Metrics::Simple;
use Perl::Metrics::Simple::TestData;
use Readonly;
use Test::More tests => 17;

Readonly::Scalar my $TEST_DIRECTORY => "$Bin/test_files";

test_main_stats();
test_summary_stats();

exit;

sub set_up {
    my $counter = Perl::Metrics::Simple->new;
    return $counter;
}

sub test_main_stats {
    my $counter = set_up();

    my @files_to_test = qw(main_subs_and_pod.pl end_token.pl);

    foreach my $test_file (@files_to_test) {
        my $path_to_test_file
            = File::Spec->join( $Bin, 'more_test_files', $test_file );
        require $path_to_test_file;
        my ( $pkg_name, $suffix ) = split / \. /x, $test_file;
        my $var_name       = '$' . $pkg_name . '::' . 'EXPECTED_NON_SUB_LINES';
        my $expected_count = eval "$var_name";
        if ( !$expected_count ) {
            Test::More::BAIL_OUT(
                "Could not get expected value from '$path_to_test_file'");
        }    
        my $analysis = $counter->analyze_files($path_to_test_file);
        Test::More::is( $analysis->main_stats()->{'lines'},
            $expected_count, "main_stats() number of lines for '$test_file'" );
    }

    return 1;
}

sub test_summary_stats {
    my $counter    = set_up();
    my $analysis   = $counter->analyze_files($TEST_DIRECTORY);
    my $sub_length = $analysis->summary_stats->{sub_length};
    cmp_ok( $sub_length->{min},    '==', 1,   'minimum sub length.' );
    cmp_ok( $sub_length->{max},    '==', 9,   'maximum sub length.' );
    cmp_ok( $sub_length->{mean},   '==', 4.57, 'mean (average) sub length.' );
    cmp_ok( $sub_length->{median}, '==', 3,   'median sub length.' );
    cmp_ok( $sub_length->{standard_deviation},
        '==', 3.02, 'standard deviation of sub length.' );

    my $sub_complexity = $analysis->summary_stats->{sub_complexity};
    cmp_ok( $sub_complexity->{min}, '==', 1, 'minimum sub complexity.' );
    cmp_ok( $sub_complexity->{max}, '==', 8, 'maximum sub complexity.' );
    cmp_ok( $sub_complexity->{mean},
        '==', 2.57, 'mean (average) sub complexity.' );
    cmp_ok( $sub_complexity->{median}, '==', 1, 'median sub complexity.' );
    cmp_ok( $sub_complexity->{standard_deviation},
        '==', 2.61, 'standard deviation of sub complexity.' );

    my $main_complexity = $analysis->summary_stats->{main_complexity};
    cmp_ok( $main_complexity->{min}, '==', 0, 'minimum main complexity.' );
    cmp_ok( $main_complexity->{max}, '==', 3, 'maximum main complexity.' );
    cmp_ok( $main_complexity->{mean},
        '==', 1.33, 'mean (average) main complexity.' );
    cmp_ok( $main_complexity->{median}, '==', 1, 'median main complexity.' );
    cmp_ok( $main_complexity->{standard_deviation},
        '==', 0.94, 'standard deviation of main complexity.' );

    return 1;
}

