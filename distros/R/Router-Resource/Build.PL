use strict;
use warnings;
use Module::Build;

Module::Build->new(
    module_name        => 'Router::Resource',
    license            => 'perl',
    create_makefile_pl => 'traditional',
    configure_requires => { 'Module::Build' => '0.30', },
    build_requires     => {
        'Module::Build' => '0.30',
        'Test::More'    => '0.70',
    },
    requires => {
        'Router::Simple' => '0.07',
        'Sub::Exporter'  => 0,
        'perl'           => 5.008001,
    },
    recommends => {
        'Test::Pod'           => '1.41',
        'Test::Pod::Coverage' => '1.06',
    },
    meta_merge => {
        resources => {
            homepage   => 'http://search.cpan.org/dist/Router-Resource/',
            bugtracker => 'http://github.com/theory/router-resource/issues/',
            repository => 'http://github.com/theory/router-resource',
        }
    },
)->create_build_script;
