use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'PGObject::Composite::Role',
    AUTHOR           => q{Chris Travers <chris@efficito.com>},
    VERSION_FROM     => 'lib/PGObject/Composite/Role.pm',
    ABSTRACT_FROM    => 'lib/PGObject/Composite/Role.pm',
    LICENSE          => 'BSD',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.008,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'PGObject::Composite'       => 0,
        'Moo::Role'                 => 0,
        'PGObject'                  => '1.402.5',
        'PGObject::Type::Composite' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'PGObject-Composite-Role-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
         resources => {
             repository => {
                 type => 'git',
                 url  => 'https://github.com/ledgersmb/PGObject-Composite-Role.git',
                 web  => 'https://github.com/ledgersmb/PGObject-Composite-Role',
             },
         },
    },
);
