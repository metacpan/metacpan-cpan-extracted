use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Nagios::Downtime',
    AUTHOR              => 'quatrix <evil.legacy AT gmail.com>',
    VERSION_FROM        => 'lib/Nagios/Downtime.pm',
    ABSTRACT_FROM       => 'lib/Nagios/Downtime.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Nagios-Downtime-*' },
);
