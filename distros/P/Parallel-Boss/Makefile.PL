use 5.012;
use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;

WriteMakefile(
    NAME          => 'Parallel::Boss',
    AUTHOR        => q{Pavel Shaydo <zwon@cpan.org>},
    LICENSE       => 'perl',
    VERSION_FROM  => 'lib/Parallel/Boss.pm',
    ABSTRACT_FROM => 'lib/Parallel/Boss.pm',
    PL_FILES      => {},
    OBJECT        => "Boss.o",
    LIBS          => "-lpthread",
    PREREQ_PM     => {},
    TEST_REQUIRES => {
        'Test::More' => 0.94,
        'Test::Most' => 0,
        'Path::Tiny' => 0,
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 6.64,
    },
    dist => {
        COMPRESS => 'gzip -9f',
        SUFFIX   => 'gz',
    },
    clean      => { FILES => 'Parallel-Boss-*' },
    META_MERGE => {
        resources => {
            license    => 'http://dev.perl.org/licenses/',
            homepage   => 'https://github.com/trinitum/perl-Parallel-Boss',
            bugtracker => 'https://github.com/trinitum/perl-Parallel-Boss/issues',
            repository => 'https://github.com/trinitum/perl-Parallel-Boss.git',
        },
        x_contributors => [ 'Pavel Shaydo <zwon@cpan.org>', ],
    },
);
