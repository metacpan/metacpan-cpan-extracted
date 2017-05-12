use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'MooseX::Control',
    license             => 'perl',
    dist_author         => 'Fayland Lam <fayland@gmail.com>',
    dist_version_from   => 'lib/MooseX/Control.pm',
    build_requires => {
        'Test::More' => 0,
        'Moose'      => '0.32',
        'MooseX::Types::Path::Class' => 0,
    },
    add_to_cleanup      => [ 'MooseX-Control-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
