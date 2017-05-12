use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Mojolicious::Plugin::ProRenderer',
    license             => 'Artistic_2_0',
    dist_author         => q{Sergey Lobin <ifitwasi@gmail.com>},
    dist_version_from   => 'lib/Mojolicious/Plugin/ProRenderer.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Mojolicious'           => 3.73,
        'HTML::Template::Pro'   => 0.95,
    },
    add_to_cleanup     => [ 'Mojolicious-Plugin-ProRenderer-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
