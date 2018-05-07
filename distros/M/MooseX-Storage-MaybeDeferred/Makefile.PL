use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'MooseX::Storage::MaybeDeferred',
    AUTHOR           => q{Martin Barth <martin@senfdax.de>},
    VERSION_FROM     => 'lib/MooseX/Storage/MaybeDeferred.pm',
    ABSTRACT_FROM    => 'lib/MooseX/Storage/MaybeDeferred.pm',
    LICENSE          => 'perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.008',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '1.0',
    },
    PREREQ_PM => {
        'MooseX::Storage'             => '0.52',
        'MooseX::Role::Parameterized' => '1.04',
    },
    dist  => {
        COMPRESS => 'gzip -9f',
        SUFFIX   => 'gz',
        PREOP    => 'pod2text lib/MooseX/Storage/MaybeDeferred.pm | tee README >$(DISTVNAME)/README;',
    },
    clean => { FILES => 'MooseX-Storage-MaybeDeferred-*' },
);
