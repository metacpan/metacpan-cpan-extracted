use strict;
use warnings;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir(), "inc");

use Test::Run::Builder;

my $builder = Test::Run::Builder->new(
    module_name         => 'Test::Count',
    license             => 'mit',
    dist_abstract        => "A Module to keep track of the number of tests in a script.",
    dist_author         => 'Shlomi Fish <shlomif@cpan.org>',
    dist_version_from   => 'lib/Test/Count.pm',
    configure_requires =>
    {
        'Module::Build' => '0.36',
    },
    requires => {
        'Parse::RecDescent' => 0,
        'base' => 0,
        'perl' => 5.006,
    },
    build_requires => {
        'File::Spec' => 0,
        'Test::More' => 0,
        'IO::Scalar' => 0,
        'strict' => 0,
        'warnings' => 0,
    },
    add_to_cleanup      => [ 'Test::Count-*' ],
    meta_merge =>
    {
        resources =>
        {
            repository => "http://bitbucket.org/shlomif/perl-test-count",
        },
        keywords =>
        [
            "annotations",
            "assertions",
            "count",
            "interpreter",
            "number",
            "qa",
            "sanity",
            "tap",
            "tap",
            "TAP",
            "test",
            "Test::More",
            "tests",
        ],
    },
);

$builder->create_build_script();

