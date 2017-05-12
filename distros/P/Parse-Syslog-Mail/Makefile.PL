use strict;
use ExtUtils::MakeMaker;
eval 'use ExtUtils::MakeMaker::Coverage';

WriteMakefile(
    NAME                => 'Parse::Syslog::Mail',
    LICENSE             => 'perl',
    AUTHOR              => 'Sebastien Aperghis-Tramoni <sebastien@aperghis.net>',
    VERSION_FROM        => 'lib/Parse/Syslog/Mail.pm',
    ABSTRACT_FROM       => 'lib/Parse/Syslog/Mail.pm',
    PREREQ_PM => {
        # prereqs
        'Carp'          => 0,
        'Parse::Syslog' => 0,

        # build/test prereqs
        'Test::More'    => 0,
    },
    PL_FILES            => {},
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Parse-Syslog-Mail-*' },
);
