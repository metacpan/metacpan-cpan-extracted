use 5.10.0;
use strict;
use warnings;
use Module::Build;
Module::Build->VERSION('0.4004');

my $builder = Module::Build->new(
    module_name        => 'Net::IPAM::IP',
    license            => 'perl_5',
    dist_author        => q{Karl Gaissmaier <karl.gaissmaier(at)uni-ulm.de>},
    dist_version_from  => 'lib/Net/IPAM/IP.pm',
    release_status     => 'stable',
    configure_requires => {
        'Module::Build' => '0.4004',
    },
    test_requires => {
        'Test::More' => '0',
    },
    requires => {
        'perl'             => '5.10.0',
        'namespace::clean' => '0',
        'Socket'           => '2.019',
        'Carp'             => '0',
    },
    add_to_cleanup => ['Net-IPAM-IP-*'],
);

$builder->create_build_script();
