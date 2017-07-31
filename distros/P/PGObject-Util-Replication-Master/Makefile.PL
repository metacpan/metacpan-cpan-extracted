use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'PGObject::Util::Replication::Master',
    AUTHOR           => q{Chris Travers <chris.travers@adjust.com>},
    VERSION_FROM     => 'lib/PGObject/Util/Replication/Master.pm',
    ABSTRACT_FROM    => 'lib/PGObject/Util/Replication/Master.pm',
    LICENSE          => 'bsd',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
        'Test::Exception' => '0',
    },
    PREREQ_PM => {
        'Moo' => 0,
        'DBI' => 0,
        'DBD::Pg' => 0,
        'PGObject::Util::Replication::Slot'	=> 'v0.01.02',
        'PGObject::Util::PGConfig'	=> 'v0.01.02',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'PGObject-Util-Replication-Master-*' },
);
