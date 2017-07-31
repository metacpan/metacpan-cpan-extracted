use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'PGObject::Util::Replication::Standby',
    AUTHOR           => q{Chris Travers <chris.travers@adjust.com>},
    VERSION_FROM     => 'lib/PGObject/Util/Replication/Standby.pm',
    ABSTRACT_FROM    => 'lib/PGObject/Util/Replication/Standby.pm',
    LICENSE          => 'bsd',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
	'URI' => 1,
	'URI::QueryParam' => 1,
	'Moo' => 0,
	'PGObject::Util::Replication::SMO' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'PGObject-Util-Replication-Standby-*' },
);
