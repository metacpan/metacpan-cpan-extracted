use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Palm::Progect',
    license             => 'perl',
    dist_author         => 'Michael Graham <mag-perl@occamstoothbrush.com>',
    dist_version_from   => 'lib/Palm/Progect.pm',
    requires => {
        'Test::More' => 0,
        'Palm::PDB'          => '1',
        'Palm::StdAppInfo'   => '1',
        'Palm::Raw'          => '1.008',
        'CLASS'              => '0',
        'Class::Accessor'    => '0',
        'Class::Constructor' => '0',
    },
    script_files       => 'bin/progconv',
    add_to_cleanup     => [ 'Palm-Progect-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
