use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Template::Plugin::URI',
    license             => 'perl',
    dist_author         => q{Denis Boyun <denisboyun@gmail.com>},
    dist_version_from   => 'lib/Template/Plugin/URI.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'URI' =>  1.74,
        'Template' => 2.26
    },
    add_to_cleanup     => [ 'Template-Plugin-URI-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
