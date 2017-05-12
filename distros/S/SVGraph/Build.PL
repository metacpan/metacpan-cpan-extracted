use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'SVGraph',
    license             => 'lgpl',
    dist_author         => 'Roman Fordinal <comsultia@cpan.org>',
    dist_version_from   => 'lib/SVGraph.pm',
    build_requires => {
        'Test::More' => 0,
        'SVG'        => 0,
    },
    add_to_cleanup      => [ 'SVGraph-*' ],
    create_makefile_pl => 'traditional',
    create_readme       => 1,
);

$builder->create_build_script();
