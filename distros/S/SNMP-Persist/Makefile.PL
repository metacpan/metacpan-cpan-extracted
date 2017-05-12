use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'SNMP::Persist',
    AUTHOR              => 'Anna Wiejak <anias@popoludnica.pl>',
    VERSION_FROM        => 'lib/SNMP/Persist.pm',
    ABSTRACT_FROM       => 'lib/SNMP/Persist.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'SNMP-Persist-*' },
);
