use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Physics::Ellipsometry::VASE',
    AUTHOR           => 'jtrujil1',
    VERSION_FROM     => 'lib/Physics/Ellipsometry/VASE.pm',
    ABSTRACT_FROM    => 'lib/Physics/Ellipsometry/VASE.pm',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.010',
    PREREQ_PM        => {
        'PDL'            => '2.0',
        'PDL::Fit::LM'  => 0,
        'PDL::NiceSlice' => 0,
    },
    TEST_REQUIRES => {
        'Test::More' => '0.96',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/jtrujil43/Ellipsometry.git',
                web  => 'https://github.com/jtrujil43/Ellipsometry',
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean => { FILES => 'Physics-Ellipsometry-VASE-*' },
);
