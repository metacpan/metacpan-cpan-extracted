use 5.010;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'PGObject::Composite',
    AUTHOR           => q{Chris Travers <chris@efficito.com>},
    VERSION_FROM     => 'lib/PGObject/Composite.pm',
    ABSTRACT_FROM    => 'lib/PGObject/Composite.pm',
    LICENSE          => 'BSD',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.010,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
            'PGObject::Type::Composite'   => 0,
            'PGObject'                    => '1.402.4',
            'Carp'                        => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'PGObject-Composite-*' },
);
