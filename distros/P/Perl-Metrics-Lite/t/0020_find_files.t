use strict;
use warnings;
use English qw(-no_match_vars);
use FindBin qw($Bin);
use Readonly;
use Test::More;

Readonly::Scalar my $TEST_DIRECTORY => "$Bin/test_files";
Readonly::Scalar my $EMPTY_STRING   => q{};
BEGIN { use_ok('Perl::Metrics::Lite'); }

sub set_up {
    my $finder = Perl::Metrics::Lite::FileFinder->new();
}

subtest "is_in_skip_list" => sub {
    my $finder      = set_up();
    my @paths_to_skip = qw(
        /foo/bar/.svn/hello.pl
        /foo/bar/_darcs/hello.pl
        /foo/bar/CVS/hello.pl
    );
    foreach my $path_to_skip (@paths_to_skip) {
        ok( $finder->should_be_skipped($path_to_skip),
            "is_in_skip_list($path_to_skip)" );
    }
    done_testing;
};

subtest "find_files" => sub {
    my $finder = set_up();
    eval { $finder->find_files('non/existent/path'); };
    isnt( $EVAL_ERROR, $EMPTY_STRING,
        'find_files() throws exception on missing path.' );

    my $expected_list = [
        "$TEST_DIRECTORY/Perl/Code/Analyze/Test/Module.pm",
        "$TEST_DIRECTORY/empty_file.pl",
        "$TEST_DIRECTORY/no_packages_nor_subs",
        "$TEST_DIRECTORY/package_no_subs.pl",
        "$TEST_DIRECTORY/subs_no_package.pl",
    ];
    my $found_files = $finder->find_files($TEST_DIRECTORY);
    is_deeply( $found_files, $expected_list,
        'find_files() find expected files' );
    done_testing;
};

done_testing;
