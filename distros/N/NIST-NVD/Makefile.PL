use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME           => 'NIST::NVD',
    AUTHOR         => q{C.J. Collier <cjac@google.com>},
    VERSION_FROM   => 'lib/NIST/NVD.pm',
    EXE_FILES      => ['bin/convert-nvdcve'],
    ABSTRACT_FROM  => 'lib/NIST/NVD.pm',
    LICENSE        => 'perl',
    PL_FILES       => {},
    BUILD_REQUIRES => {
        'Test::More'            => '0.98',
        'Test::File'            => '1.31',
        'Test::Pod::Coverage'   => '1.08',
        'Test::Pod'             => '1.44',
        'Perl::Critic'          => '1.117',
    },
    PREREQ_PM => {
        'JSON::XS'              => '4.03',
        'LWP::UserAgent'        => '6.61',
    },
    dist  => { COMPRESS => 'gzip --best', SUFFIX => 'gz', },
    clean => { FILES    => 'NIST-NVD-* t/data/*.db' },
);
