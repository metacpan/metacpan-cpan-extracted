use strict;
use Module::Build;
Module::Build->new(
    module_name => 'Net::DMAP::Server',
    license     => 'perl',
    requires    => {
        'perl' => 5.006,
        'POE::Component::Server::HTTP' => 0.05,
        'Net::DAAP::DMAP'              => 1.21,
        'Net::Rendezvous::Publish'     => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    create_makefile_pl => 'traditional',
   )->create_build_script;
