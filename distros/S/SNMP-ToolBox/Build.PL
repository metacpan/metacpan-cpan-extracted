#!/usr/bin/perl
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'SNMP::ToolBox',
    license             => 'perl',
    dist_author         => q{Sebastien Aperghis-Tramoni <sebastien@aperghis.net>},
    dist_version_from   => 'lib/SNMP/ToolBox.pm',
    requires => {
        'Carp'              => 0,
        'Exporter'          => 0,
        'parent'            => 0,
    },
    build_requires => {
        'Test::More'        => 0,
    },
    configure_requires => {
        'Module::Build'     => 0.38,
    },
    meta_merge => {
        resources       => {
            repository  => "https://github.com/maddingue/SNMP-ToolBox",
            #{
            #    type    => "git",
            #    url     => "git://github.com/maddingue/SNMP-ToolBox.git",
            #    web     => "https://github.com/maddingue/SNMP-ToolBox",
            #}
        }
    },
    add_to_cleanup      => [ 'SNMP-ToolBox-*' ],
);

$builder->create_build_script();
