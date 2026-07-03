use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Params::Signature',
    AUTHOR           => q{Sandor Patocs},
    VERSION_FROM     => 'lib/Params/Signature.pm',
    ABSTRACT_FROM    => 'lib/Params/Signature.pm',
    LICENSE          => 'perl',
    PL_FILES         => {},
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        # 'Carp' => "", # in core
        # 'Scalar::Util' => "1.23" # in core
        # 'Data::Dumper' => "2.0" # needed for debugging only
        'Class::Inspector' => "1.28",
        'Types::Standard' => 0,
        'Test::Requires' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Params-Signature-*' },
);
