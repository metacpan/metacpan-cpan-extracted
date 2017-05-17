use 5.010;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'PGObject::Util::BulkLoad',
    AUTHOR           => q{Chris Travers <chris.travers@gmail.com>},
    VERSION_FROM     => 'lib/PGObject/Util/BulkLoad.pm',
    ABSTRACT_FROM    => 'lib/PGObject/Util/BulkLoad.pm',
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
        DBI                 => 0,
        'DBD::Pg'           => 0,
        'Text::CSV'         => 0,
        'Memoize'           => 0,
        'Try::Tiny'         => 0,
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'PGObject-Util-BulkLoad-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
         resources => {
             repository => {
                 type => 'git',
                 url  => 'https://github.com/einhverfr/PGObject-Util-BulkLoad.git',
                 web  => 'https://github.com/einhverfr/PGObject-Util-BulkLoad',
             },
         },
    },
    
);
