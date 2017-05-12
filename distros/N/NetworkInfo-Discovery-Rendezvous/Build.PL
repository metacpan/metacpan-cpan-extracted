use strict;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'NetworkInfo::Discovery::Rendezvous',
    license             => 'perl',
    dist_author         => 'Sébastien Aperghis-Tramoni <sebastien@aperghis.net>',
    dist_version_from   => 'lib/NetworkInfo/Discovery/Rendezvous.pm',
    requires => {
        'Carp' => 0,
        'NetworkInfo::Discovery' => '0.12', 
        'Net::Rendezvous' => '0.90', 
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'NetworkInfo-Discovery-Rendezvous-*' ],
);

$builder->create_build_script();
