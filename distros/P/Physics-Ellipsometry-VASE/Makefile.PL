use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Physics::Ellipsometry::VASE',
    AUTHOR           => 'Jovan Trujillo <jtrujil1@asu.edu>',
    VERSION_FROM     => 'lib/Physics/Ellipsometry/VASE.pm',
    ABSTRACT_FROM    => 'lib/Physics/Ellipsometry/VASE.pm',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.010',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.64',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0.96',
    },
    TEST_REQUIRES => {
        'Test::More' => '0.96',
    },
    PREREQ_PM        => {
        'PDL'            => '2.0',
        'PDL::Fit::LM'  => 0,
        'PDL::NiceSlice' => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/jtrujil43/Ellipsometry.git',
                web  => 'https://github.com/jtrujil43/Ellipsometry',
            },
            bugtracker => {
                web => 'https://github.com/jtrujil43/Ellipsometry/issues',
            },
        },
        no_index => {
            directory => [ 'data', 'examples' ],
        },
    },
    dist      => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean     => { FILES => 'Physics-Ellipsometry-VASE-*' },
    PM        => {
        'lib/Physics/Ellipsometry/VASE.pm' =>
            '$(INST_LIB)/Physics/Ellipsometry/VASE.pm',
        'lib/Physics/Ellipsometry/VASE/TMM.pm' =>
            '$(INST_LIB)/Physics/Ellipsometry/VASE/TMM.pm',
        'lib/Physics/Ellipsometry/VASE/Dispersion.pm' =>
            '$(INST_LIB)/Physics/Ellipsometry/VASE/Dispersion.pm',
        'lib/Physics/Ellipsometry/VASE/EMA.pm' =>
            '$(INST_LIB)/Physics/Ellipsometry/VASE/EMA.pm',
        'lib/Physics/Ellipsometry/VASE/Materials.pm' =>
            '$(INST_LIB)/Physics/Ellipsometry/VASE/Materials.pm',
        'lib/Physics/Ellipsometry/VASE/Parameter.pm' =>
            '$(INST_LIB)/Physics/Ellipsometry/VASE/Parameter.pm',
        'lib/Physics/Ellipsometry/VASE/Optimizer.pm' =>
            '$(INST_LIB)/Physics/Ellipsometry/VASE/Optimizer.pm',
        'lib/PDL/Demos/Ellipsometry.pm' =>
            '$(INST_LIB)/PDL/Demos/Ellipsometry.pm',
        'lib/PDL/Demos/demo_wafer.dat' =>
            '$(INST_LIB)/PDL/Demos/demo_wafer.dat',
        'lib/PDL/Demos/demo_ta_metal.mat' =>
            '$(INST_LIB)/PDL/Demos/demo_ta_metal.mat',
    },
);
