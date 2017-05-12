use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'RPM::Packager',
    AUTHOR             => q{Satoshi Yagi <satoshi.yagi@yahoo.com>},
    VERSION_FROM       => 'lib/RPM/Packager.pm',
    ABSTRACT_FROM      => 'lib/RPM/Packager.pm',
    LICENSE            => 'gpl_3',
    PL_FILES           => {},
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    EXE_FILES => ['bin/rpm_packager.pl'],
    PREREQ_PM => {
        'Expect' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'RPM-Packager-*' },
);
