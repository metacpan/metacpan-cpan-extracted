use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Pg::Queue',
    AUTHOR           => q{Robert Grimes <rmzgrimes@gmail.com>},
    VERSION_FROM     => 'lib/Pg/Queue.pm',
    ABSTRACT_FROM    => 'lib/Pg/Queue.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'Moo'     => 0,
				'DBI'     => 0,
				'DBD::Pg' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Pg-Queue-*' },
);
