use 5.10.1;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Mojolicious::Plugin::MostTagHelpers',
    license             => 'Artistic_2_0',
    dist_author         => q{Holger Rupprecht <holger.rupprecht@gmx.de>},
    dist_version_from   => 'lib/Mojolicious/Plugin/MostTagHelpers.pm',
    release_status      => 'stable',
    configure_requires => {
      'Module::Build' => 0,
    },
    build_requires => {
      'Test::More' => 0,
    },
    requires => {
      'Mojolicious'    => 4.66,    
      'HTML::Tagset'   => 3.20,
    },
    add_to_cleanup     => [ 'Mojolicious-Plugin-MostTagHelpers-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
