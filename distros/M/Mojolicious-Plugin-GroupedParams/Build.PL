use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Mojolicious::Plugin::GroupedParams',
    license             => 'perl',
    dist_author         => q{Ivan Sokolov <ivsokolov@cpan.org>},
    dist_version_from   => 'lib/Mojolicious/Plugin/GroupedParams.pm',
    build_requires => {
        'Test::More'  => 0,
        'Mojolicious' => 0.999950,
    },
    add_to_cleanup      => [ 'Mojolicious-Plugin-GroupedParams-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
