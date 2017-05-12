use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'MooseX::Struct',
    license             => 'perl',
    dist_author         => 'Jarrod Overson <jsoverson@googlemail.com>',
    dist_abstract       => 'Struct-like interface for Moose',
    dist_version_from   => 'lib/MooseX/Struct.pm',
    build_requires      => {
        'Test::More' => 0,
    },
    requires            => {
        'Moose'         => 0,
        'Sub::Install'  => 0,
         'Carp'         => 0,
    },
    add_to_cleanup      => [ 'MooseX-Struct-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
