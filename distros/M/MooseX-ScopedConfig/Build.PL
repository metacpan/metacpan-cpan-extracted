use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'MooseX::ScopedConfig',
    license             => 'perl',
    dist_author         => q{Brad Barden <iamb@mifflinet.net>},
    dist_version_from   => 'lib/MooseX/ScopedConfig.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl' => 5.006,
        'Config::Scoped' => 0,
        'Moose::Role' => 0,
        'MooseX::ConfigFromFile' => 0,
    },
    add_to_cleanup      => [ 'MooseX-ScopedConfig-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
