use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name        => 'Privileges::Drop',
    license            => 'perl',
    dist_author        => 'Troels Liebe Bentsen <troels@infopro.dk>',
    dist_version_from  => 'lib/Privileges/Drop.pm',
    create_makefile_pl => 'passthrough',
    create_readme      => 1,
    requires => {
        'Carp'    => 0,
        'English' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup => [ 
        'Privileges-Drop-*',
        'Makefile',
        'blib',
    ],
);

$builder->create_build_script();
