use strict;
use warnings;
use English qw(-no_match_vars);
use Data::Dumper;
use File::Spec qw();
use FindBin qw($Bin);
use lib "$Bin/lib";
use Perl::Metrics::Lite::TestData;
use Readonly;
use Test::More;

Readonly::Scalar my $TEST_DIRECTORY => "$Bin/test_files";
Readonly::Scalar my $EMPTY_STRING   => q{};

BEGIN {
    use_ok('Perl::Metrics::Lite')
        || BAIL_OUT('Could not compile Perl::Metrics::Lite');
    use_ok('Perl::Metrics::Lite::Analysis::File')
        || BAIL_OUT('Could not compile Perl::Metrics::Lite::Analysis::File');
}

sub set_up {
    my $test_data_object = Perl::Metrics::Lite::TestData->new(
        test_directory => $TEST_DIRECTORY );
    return $test_data_object;
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path;
    my $contents = do { local $INPUT_RECORD_SEPARATOR; <$fh> };
    close $fh;
    return \$contents;
}

subtest "test_analyze_one_file" => sub {
    my $test_data_object = set_up();
    my $test_data        = $test_data_object->get_test_data;
    my $no_package_no_sub_expected_result
        = $test_data->{'no_packages_nor_subs'};
    my $analysis = Perl::Metrics::Lite::Analysis::File->new(
        path => $no_package_no_sub_expected_result->{'path'} );
    is_deeply( $analysis->subs, [], 'Analysis of file with no subs.' );

    my $has_package_no_subs_expected_result
        = $test_data->{'package_no_subs.pl'};
    my $new_analysis = Perl::Metrics::Lite::Analysis::File->new(
        path => $has_package_no_subs_expected_result->{'path'} );
    is_deeply(
        $new_analysis->packages,
        $has_package_no_subs_expected_result->{packages},
        'Analysis of file with one package.'
    );
    is_deeply( $new_analysis->subs, [],
        'Analysis of file with one package and no subs.' );

    my $has_subs_expected_result = $test_data->{'subs_no_package.pl'};
    my $has_subs_analysis        = Perl::Metrics::Lite::Analysis::File->new(
        path => $has_subs_expected_result->{'path'} );

    #is_deeply( $has_subs_analysis->all_counts,
    #    $has_subs_expected_result, 'analyze_one_file() subs_no_package.pl' );

    #my $has_subs_and_package_expected_result = $test_data->{'Module.pm'};
    #my $subs_and_package_analysis = Perl::Metrics::Lite::Analysis::File->new(
    #    path => $has_subs_and_package_expected_result->{'path'} );
    #is_deeply(
    #    $subs_and_package_analysis->all_counts,
    #    $has_subs_and_package_expected_result,
    #    'analyze_one_file() with packages and subs.'
    #);
    done_testing;
};

subtest "test_analyze_files" => sub {
    my $test_data_object = set_up();
    my $test_data        = $test_data_object->get_test_data;
    my $analyzer         = Perl::Metrics::Lite->new();
    my $analysis_of_one_file
        = $analyzer->analyze_files( $test_data->{'Module.pm'}->{path} );
    isa_ok( $analysis_of_one_file, 'Perl::Metrics::Lite::Analysis' );
    my $expected_from_one_file = $test_data->{'Module.pm'};
    is( scalar @{ $analysis_of_one_file->data },
        1, 'Analysis has only 1 element.' );
    isa_ok(
        $analysis_of_one_file->data->[0],
        'Perl::Metrics::Lite::Analysis::File'
    );

    #    is_deeply( $analysis_of_one_file->data->[0]->all_counts,
    #       $expected_from_one_file,
    #        'analyze_files() when given a single file path.' )
    #        || diag Dumper $analysis_of_one_file->data;

    my $analysis = $analyzer->analyze_files($TEST_DIRECTORY);
    my @expected = (
        $test_data->{'Module.pm'},
        $test_data->{'empty_file.pl'},
        $test_data->{'no_packages_nor_subs'},
        $test_data->{'package_no_subs.pl'},
        $test_data->{'subs_no_package.pl'},
    );
    is( scalar @{ $analysis->data },
        scalar @expected,
        'analayze_files() gets right number of files.'
    );

    #    for my $i ( scalar @expected ) {
    #        is_deeply( $analysis->data->[$i],
    #            $expected[$i], 'Got expected results for test file.' );
    #    }
    done_testing;
};

subtest "test_analysis" => sub {
    my $test_data_object = set_up();
    my $test_data        = $test_data_object->get_test_data;
    my $analyzer         = Perl::Metrics::Lite->new;
    my $analysis         = $analyzer->analyze_files($TEST_DIRECTORY);

    my @expected_files = (
        $test_data->{'Module.pm'}->{path},
        $test_data->{'empty_file.pl'}->{path},
        $test_data->{'no_packages_nor_subs'}->{path},
        $test_data->{'package_no_subs.pl'}->{path},
        $test_data->{'subs_no_package.pl'}->{path},
    );
    is_deeply( $analysis->files, \@expected_files,
        'analysis->files() contains expected files.' );
    is( $analysis->file_count,
        scalar @expected_files,
        'file_count() returns correct number.'
    );

    my @expected_subs = ();
    foreach my $test_file ( sort keys %{$test_data} ) {
        my @subs = @{ $test_data->{$test_file}->{subs} };
        if ( scalar @subs ) {
            push @expected_subs, @subs;
        }
    }

    #is_deeply( $analysis->subs, \@expected_subs,
    #    'analysis->subs() returns expected list.' );

    is( $analysis->sub_count,
        scalar @expected_subs,
        'analysis->subs_count returns correct number.'
    );

    my $expected_file_stats = $test_data_object->get_file_stats;

    #is_deeply( $analysis->file_stats, $expected_file_stats,
    #    'analysis->file_stats returns expected data.' );

    done_testing;
};

subtest "test_new" => sub {
    eval { my $analysis = Perl::Metrics::Lite::Analysis->new() };
    like(
        $EVAL_ERROR,
        qr/Did not supply an arryref of analysis data/,
        'new() throws exception when no data supplied.'
    );

    my $test_path_1
        = File::Spec->join( $TEST_DIRECTORY, 'package_no_subs.pl' );
    my $file_object_1
        = Perl::Metrics::Lite::Analysis::File->new( path => $test_path_1 );
    my $test_path_2
        = File::Spec->join( $TEST_DIRECTORY, 'subs_no_package.pl' );
    my $file_object_2
        = Perl::Metrics::Lite::Analysis::File->new( path => $test_path_2 );
    my $analysis = Perl::Metrics::Lite::Analysis->new(
        [ $file_object_1, $file_object_2 ] );

    isa_ok( $analysis, 'Perl::Metrics::Lite::Analysis' );

    done_testing;
};

subtest "test_is_ref" => sub {
    my $not_a_ref = 'hello';
    is( Perl::Metrics::Lite::Analysis::Util::is_ref( $not_a_ref, 'ARRAY' ),
        undef, 'is_ref() returns undef on a string.' );
    my $array_ref = [];
    ok( Perl::Metrics::Lite::Analysis::Util::is_ref( $array_ref, 'ARRAY' ),
        'is_ref() returns true for ARRAY ref.' );
    my $hash_ref = {};
    ok( Perl::Metrics::Lite::Analysis::Util::is_ref( $hash_ref, 'HASH' ),
        'is_ref() returns true for HASH ref.' );
    is( Perl::Metrics::Lite::Analysis::Util::is_ref( $array_ref, 'HASH' ),
        undef, 'is_ref() knows an array ref is not a HASH' );
    done_testing;
};

done_testing;
