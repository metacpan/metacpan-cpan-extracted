use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'PGObject::Util::Replication::SMO',
    AUTHOR           => q{Chris Travers <chris.travers@adjust.com>},
    VERSION_FROM     => 'lib/PGObject/Util/Replication/SMO.pm',
    ABSTRACT_FROM    => 'lib/PGObject/Util/Replication/SMO.pm',
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
	'Moo' => 1,
	'DBI' => 1,
	'DBD::Pg' => 3,
	'PGObject::Util::PGConfig' => 0,
	'PGObject::Util::Replication::Slot' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'PGObject-Util-Replication-SMO-*' },
);
