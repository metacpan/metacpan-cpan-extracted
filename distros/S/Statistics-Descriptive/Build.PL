use strict;
use warnings;

use lib "./inc";

use Test::Run::Builder;

my $builder = Test::Run::Builder->new(
    module_name         => 'Statistics::Descriptive',
    license             => 'perl',
    dist_author         => 'Shlomi Fish <shlomif@cpan.org>',
    dist_version_from   => 'lib/Statistics/Descriptive.pm',
    configure_requires => {
        'Module::Build' => '0.36',
    },
    build_requires => {
        'Benchmark' => 0,
        'lib' => 0,
        'Test::More' => 0,
    },
    requires => {
        'Carp' => 0,
        'List::MoreUtils' => 0,
        'List::Util' => 0,
        'POSIX' => 0,
        'perl' => '5.006',
        'strict' => 0,
        'vars' => 0,
        'warnings' => 0,
    },
    add_to_cleanup      => [ 'Statistics-Descriptive-*' ],
    create_makefile_pl => 'traditional',
    PL_files => {},
    meta_merge =>
    {
        resources =>
        {
            repository => "https://github.com/shlomif/perl-Statistics-Descriptive",
            homepage => "http://web-cpan.shlomifish.org/modules/Statistics-Descriptive/",
        },
        keywords =>
        [
            qw(
                average
                distribution
                mean
                median
                statistics
                stats
                stddev
            ),
            "standard deviation"
        ],
    },
);

$builder->create_build_script();
