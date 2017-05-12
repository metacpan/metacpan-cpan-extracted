#!/usr/bin/perl
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'SNMP::ToolBox',
    LICENSE             => 'perl',
    AUTHOR              => q{Sebastien Aperghis-Tramoni <sebastien@aperghis.net>},
    VERSION_FROM        => 'lib/SNMP/ToolBox.pm',
    ABSTRACT_FROM       => 'lib/SNMP/ToolBox.pm',
    PREREQ_PM => {
        # prereqs
        'Carp'              => 0,
        'Exporter'          => 0,
        'parent'            => 0,

        # build/test prereqs
        'Test::More'    => 0,
    },
    META_MERGE          => {
        resources       => {
            repository  => "https://github.com/maddingue/SNMP-ToolBox",
            #{
            #    type    => "git",
            #    url     => "git://github.com/maddingue/SNMP-ToolBox.git",
            #    web     => "https://github.com/maddingue/SNMP-ToolBox",
            #}
        }
    },
    PL_FILES            => {},
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'SNMP-ToolBox-*' },
);
