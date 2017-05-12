use strict;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'NetworkInfo::Discovery::Nmap',
    license             => 'perl',
    dist_author         => 'Sébastien Aperghis-Tramoni <sebastien@aperghis.net>',
    dist_version_from   => 'lib/NetworkInfo/Discovery/Nmap.pm',
    requires => {
        'Carp' => 0,
        'NetworkInfo::Discovery' => '0.12', 
        'Nmap::Scanner' => '0.7', 
        'Sys::Hostname' => 0,
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'NetworkInfo-Discovery-Nmap-*' ],
);

$builder->create_build_script();
