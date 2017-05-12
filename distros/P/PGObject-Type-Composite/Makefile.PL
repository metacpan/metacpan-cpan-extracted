use 5.008;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'PGObject::Type::Composite',
    AUTHOR           => q{Chris Travers <chris.travers@gmail.com>},
    VERSION_FROM     => 'lib/PGObject/Type/Composite.pm',
    ABSTRACT_FROM    => 'lib/PGObject/Type/Composite.pm',
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
        DBI                              => 0,
        'PGObject::Util::PseudoCSV'      => '1.1.0',
        'PGObject::Util::Catalog::Types' => 0,
        'Carp'                           => 0,
        'Scalar::Util'                   => 0,
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'PGObject-Type-Composite-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
         resources => {
             repository => {
                 type => 'git',
                 url  => 'https://github.com/ledgersmb/PGObject-Type-Composite.git',
                 web  => 'https://github.com/ledgersmb/PGObject-Type-Composite',
             },
         },
    },
);
