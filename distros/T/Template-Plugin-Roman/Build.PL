use v5.10;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Template::Plugin::Roman',
    license             => 'perl',
    dist_author         => q{Jon Sime <jonsime@gmail.com>},
    dist_version_from   => 'lib/Template/Plugin/Roman.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Template'    => '2.07',
        'Math::Roman' => '1.07',
    },
    add_to_cleanup     => [ 'Template-Plugin-Roman-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
