use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Mojolicious::Plugin::Toto',
    license             => 'perl',
    dist_author         => q{Brian Duggan <bduggan@matatu.org>},
    dist_version_from   => 'lib/Mojolicious/Plugin/Toto.pm',
    requires            => {
            'Mojolicious' => '3.84',
        },
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Mojolicious-Plugin-Toto-*' ],
    create_makefile_pl => 'traditional',
    meta_merge => {
        resources => {
            repository => 'https://github.com/bduggan/Mojolicious-Plugin-Toto',
        },
    },
);

$builder->add_build_element('ep');
$builder->add_build_element('css');
$builder->add_build_element('js');
$builder->add_build_element('png');
$builder->create_build_script();
