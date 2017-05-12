use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Mojolicious::Plugin::AdvancedMod',
    license             => 'perl',
    dist_author         => q{Grishkovelli <grishkovelli@gmail.com>},
    dist_version_from   => 'lib/Mojolicious/Plugin/AdvancedMod.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Text::Haml'    => 0,
        'DBI'           => 0,
    },
    meta_merge => {
        resources => {
            repository => 'https://github.com/grishkovelli/Mojolicious-Plugin-AdvancedMod',
        }
    },
    add_to_cleanup     => [ 'Mojolicious-Plugin-AdvancedMod-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
