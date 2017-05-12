#!/usr/bin/perl
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'POE::Component::NetSNMP::agent',
    LICENSE             => 'perl',
    AUTHOR              => 'Sebastien Aperghis-Tramoni <sebastien@aperghis.net>',
    VERSION_FROM        => 'lib/POE/Component/NetSNMP/agent.pm',
    ABSTRACT_FROM       => 'lib/POE/Component/NetSNMP/agent.pm',
    PREREQ_PM => {
        # prereqs
        'Carp'              => 0,
        'List::MoreUtils'   => 0,
        'NetSNMP::agent'    => 5.0000,
        'parent'            => 0,
        'POE'               => 0.3502,
        'SNMP'              => 5.0000,
        'SNMP::ToolBox'     => 0.01,
        'version'           => 0,

        # build/test prereqs
        'Test::More'        => 0,
    },
    META_MERGE          => {
        resources       => {
            repository  => "https://github.com/maddingue/POE-Component-NetSNMP-agent",
            #{
            #    type    => "git",
            #    url     => "git://github.com/maddingue/POE-Component-NetSNMP-agent.git",
            #    web     => "https://github.com/maddingue/POE-Component-NetSNMP-agent",
            #}
        },
    },
    PL_FILES            => {},
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'POE-Component-NetSNMP-agent-*' },
);
