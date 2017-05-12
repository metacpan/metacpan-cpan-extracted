use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'String::Blender',
    license             => 'perl',
    dist_author         => 'Alexey Skorikov <alexey@skorikov.name>',
    dist_version_from   => 'lib/String/Blender.pm',
    requires => {
        'Test::More' => 0,
        'Moose'      => 0.74,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'String-Blender-*' ],
);

$builder->create_build_script();
