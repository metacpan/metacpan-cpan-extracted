#!/usr/bin/perl
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'POE::Component::NetSNMP::agent',
    license             => 'perl',
    dist_author         => 'Sebastien Aperghis-Tramoni <sebastien@aperghis.net>',
    dist_version_from   => 'lib/POE/Component/NetSNMP/agent.pm',
    requires => {
        'Carp'              => 0,
        'List::MoreUtils'   => 0,
        'NetSNMP::agent'    => 5.0000,
        'parent'            => 0,
        'POE'               => 0.3502,
        'SNMP'              => 5.0000,
        'SNMP::ToolBox'     => 0.01,
        'version'           => 0,
    },
    build_requires => {
        'Test::More'        => 0,
    },
    configure_requires => {
        'Module::Build'     => 0.38,
    },
    meta_merge => {
        resources       => {
            repository  => "https://github.com/maddingue/POE-Component-NetSNMP-agent",
            #{
            #    type    => "git",
            #    url     => "git://github.com/maddingue/POE-Component-NetSNMP-agent.git",
            #    web     => "https://github.com/maddingue/POE-Component-NetSNMP-agent",
            #}
        },
    },
    add_to_cleanup      => [ 'POE-Component-NetSNMP-agent-*' ],
);

$builder->create_build_script();
