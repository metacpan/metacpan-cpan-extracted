use strict;
use warnings;
use File::Spec qw();
use FindBin qw($Bin);
use lib "$Bin/lib";
use Perl::Metrics::Lite;
use Perl::Metrics::Lite::TestData;
use Perl::Metrics::Lite::Analysis::Util;
use Readonly;
use Test::More;

Readonly::Scalar my $TEST_DIRECTORY => "$Bin/test_files";

test_main_stats();
done_testing;

exit;

sub set_up {
    my $counter = Perl::Metrics::Lite->new;
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
        my $var_name       = '$' . $pkg_name . '::' . 'EXPECTED_LOC';
        my $expected_count = eval "$var_name";
        if ( !$expected_count ) {
            Test::More::BAIL_OUT(
                "Could not get expected value from '$path_to_test_file'");
        }
        my $analysis = $counter->analyze_files($path_to_test_file);
        Test::More::is( $analysis->main_stats()->{'lines'},
            $expected_count,
            "main_stats() number of lines for '$test_file'" );
    }

    return 1;
}

