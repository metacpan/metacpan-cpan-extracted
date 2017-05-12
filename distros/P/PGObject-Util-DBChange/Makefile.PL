use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'PGObject::Util::DBChange',
    AUTHOR           => q{Chris Travers <chris.travers@gmail.com>},
    VERSION_FROM     => 'lib/PGObject/Util/DBChange.pm',
    ABSTRACT_FROM    => 'lib/PGObject/Util/DBChange.pm',
    LICENSE          => 'bsd',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.010,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Digest::SHA' => 0,
        'Moo'         => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'PGObject-Util-DBChange-*' },
);
