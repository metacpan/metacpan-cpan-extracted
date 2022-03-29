use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME      => 'NIST::NVD::Store::SQLite3',
    AUTHOR    => q{C.J. Adams-Collier <cjac@uw.edu>},
    EXE_FILES => ['bin/convert-nvdcve'],

    VERSION_FROM   => 'lib/NIST/NVD/Store/SQLite3.pm',
    ABSTRACT_FROM  => 'lib/NIST/NVD/Store/SQLite3.pm',
    LICENSE        => 'perl',
    PL_FILES       => {},
    BUILD_REQUIRES => {
        'Test::More'            => 0,
        'Test::Pod::Coverage'   => 0,
        'Test::Pod'             => 0,
        'Perl::Critic'          => 0,
        'XML::XPath'            => 0,
        'XML::XPath::XMLParser' => 0,
        'File::MMagic'          => 0,
        'File::LibMagic'        => 0,
    },
    PREREQ_PM => {
        'Time::HiRes'  => 0,
        DBI            => 0,
        'DBD::SQLite'  => 0,
        'XML::XPath'   => 0,
        'NIST::NVD'    => 1,
    },
    dist  => { COMPRESS => 'gzip --best', SUFFIX => 'gz', },
    clean => { FILES    => 'NIST-NVD-Store-SQLite3-*' },
);
