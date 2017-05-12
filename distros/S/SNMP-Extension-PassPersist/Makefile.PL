use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'SNMP::Extension::PassPersist',
    AUTHOR              => 'Sebastien Aperghis-Tramoni <sebastien@aperghis.net>',
    VERSION_FROM        => 'lib/SNMP/Extension/PassPersist.pm',
    ABSTRACT_FROM       => 'lib/SNMP/Extension/PassPersist.pm',
    PREREQ_PM => {
        # prereqs
        'Carp'              => 0,
        'Class::Accessor'   => '0.30',
        'File::Basename'    => 0,
        'Getopt::Long'      => '2.04',
        'IO::Handle'        => '1.15',
        'IO::Pipe'          => '1.12',
        'IO::Select'        => '1.10',
        'List::MoreUtils'   => '0.21',
        'parent'            => '0.221',
        'Sys::Syslog'       => 0,

        # build/test prereqs
        'File::Temp'        => '0.14',
        'IO::File'          => '1.05',
        'IO::String'        => '1.00',
        'Test::More'        => '0.45',
    },
    META_MERGE => {
        resources       => {
            repository  => "https://github.com/maddingue/SNMP-Extension-PassPersist",
            #{
            #    type    => "git",
            #    url     => "git://github.com/maddingue/SNMP-Extension-PassPersist.git",
            #    web     => "https://github.com/maddingue/SNMP-Extension-PassPersist",
            #}
        },
    },
    PL_FILES            => {},
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'SNMP-Extension-PassPersist-*' },
);
