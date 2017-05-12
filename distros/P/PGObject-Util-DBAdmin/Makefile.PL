use 5.008;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'PGObject::Util::DBAdmin',
    AUTHOR           => q{Chris Travers <chris@efficito.com>},
    VERSION_FROM     => 'lib/PGObject/Util/DBAdmin.pm',
    ABSTRACT_FROM    => 'lib/PGObject/Util/DBAdmin.pm',
    LICENSE          => 'BSD',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.008,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'Test::Exception' => 0,
    },
    PREREQ_PM => {
        'DBD::Pg'       => 0,
        'Capture::Tiny' => 0,
        'DBI'           => 0,
        'Moo'           => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'PGObject-Util-DBAdmin-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
         resources => {
             repository => {
                 type => 'git',
                 url  => 'https://github.com/einhverfr/PGObject-Util-DBAdmin.git',
                 web  => 'https://github.com/einhverfr/PGObject-Util-DBAdmin',
             },
         },
    },
);
