use 5.010;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'PGObject::Util::Catalog::Types',
    AUTHOR           => q{Chris Travers <chris.travers@gmail.com>},
    VERSION_FROM     => 'lib/PGObject/Util/Catalog/Types.pm',
    ABSTRACT_FROM    => 'lib/PGObject/Util/Catalog/Types.pm',
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
        'Exporter' => 0,
        'Memoize'  => 0,
        'DBI'      => 0,
	'DBD::Pg'  => 0,
        'Carp'     => 0
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'PGObject-Util-Catalog-Types-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
    'meta-spec' => { version => 2 },
     resources => {
         repository => {
             type => 'git',
             url  => 'https://github.com/ledgersmb/PGObject-Util-Catalog-Types.git',
             web  => 'https://github.com/ledgersmb/PGObject-Util-Catalog-Types',
         },
     }})
     : ()
    ),
);
