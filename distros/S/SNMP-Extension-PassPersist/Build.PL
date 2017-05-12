use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'SNMP::Extension::PassPersist',
    license             => 'perl',
    dist_author         => 'Sebastien Aperghis-Tramoni <sebastien@aperghis.net>',
    dist_version_from   => 'lib/SNMP/Extension/PassPersist.pm',
    requires => {
        'perl'              => '5.006',
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
    },
    recommends => {
        'Sort::Key::OID'    => '0.04',
    },
    build_requires => {
        'File::Temp'        => '0.14',
        'IO::File'          => '1.05',
        'IO::String'        => '1.00',
        'Test::More'        => '0.45',
    },
    meta_merge => {
        resources       => {
            repository  => "https://github.com/maddingue/SNMP-Extension-PassPersist",
            #{
            #    type    => "git",
            #    url     => "git://github.com/maddingue/SNMP-Extension-PassPersist.git",
            #    web     => "https://github.com/maddingue/SNMP-Extension-PassPersist",
            #}
        },
    },
    add_to_cleanup      => [ 'SNMP-Extension-PassPersist-*' ],
);

$builder->create_build_script();
