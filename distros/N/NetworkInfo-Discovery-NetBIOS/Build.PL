use strict;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'NetworkInfo::Discovery::NetBIOS',
    license             => 'perl',
    dist_author         => 'Sébastien Aperghis-Tramoni <sebastien@aperghis.net>',
    dist_version_from   => 'lib/NetworkInfo/Discovery/NetBIOS.pm',
    requires => {
        'Carp' => 0,
        'NetworkInfo::Discovery' => 0.12, 
        'Net::NBName' => 0.25, 
        'Net::Netmask' => 0, 
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'NetworkInfo-Discovery-NetBIOS-*' ],
);

$builder->create_build_script();
