use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Mojolicious::Plugin::MultiConfig',
    license             => 'artistic_2',
    dist_author         => q{Ben Vinnerd <ben@vinnerd.com>},
    dist_version_from   => 'lib/Mojolicious/Plugin/MultiConfig.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Config::Any' => 0.24,
    },
    add_to_cleanup     => [ 'Mojolicious-Plugin-MultiConfig-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
