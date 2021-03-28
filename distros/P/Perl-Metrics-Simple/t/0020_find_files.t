use strict;
use warnings;
use English qw(-no_match_vars);
use FindBin qw($Bin);
use Readonly 1.03;
use Test::More tests => 6;

Readonly::Scalar my $TEST_DIRECTORY => "$Bin/test_files";
Readonly::Scalar my $EMPTY_STRING   => q{};
BEGIN { use_ok('Perl::Metrics::Simple'); }

test_find_files();
test_is_in_skip_list();

exit;

sub set_up {
    my $analyzer = Perl::Metrics::Simple->new();
}

sub test_is_in_skip_list {
    my $analyzer = set_up();
    my @paths_to_skip = qw(
        /foo/bar/.svn/hello.pl
        /foo/bar/_darcs/hello.pl
        /foo/bar/CVS/hello.pl
    );
    foreach my $path_to_skip ( @paths_to_skip ) {
        ok($analyzer->should_be_skipped($path_to_skip), "is_in_skip_list($path_to_skip)");
    }
}

sub test_find_files {
    my $analyzer = set_up();
    eval { $analyzer->find_files('non/existent/path'); };
    isnt( $EVAL_ERROR, $EMPTY_STRING,
        'find_files() throws exception on missing path.' );

    my $expected_list = [
        "$TEST_DIRECTORY/Perl/Code/Analyze/Test/Module.pm",
        "$TEST_DIRECTORY/Perl/Code/Analyze/Test/Moose.pm",
        "$TEST_DIRECTORY/empty_file.pl",
        "$TEST_DIRECTORY/no_packages_nor_subs",
        "$TEST_DIRECTORY/package_no_subs.pl",
        "$TEST_DIRECTORY/subs_no_package.pl",
    ];    
    my $found_files = $analyzer->find_files($TEST_DIRECTORY);
    is_deeply( $found_files, $expected_list,
        'find_files() find expected files' );
}
