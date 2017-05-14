use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Phenyx::Utils',
    license             => 'lgpl',
    dist_author         => 'Alexandre Masselot <Alexandre_dot_masselot_at_genebio_dot_com>',
    dist_version_from   => 'lib/Phenyx/Utils.pm',
    requires => {
        'Test::More' => 0,
        'File::Basename' => 0,
        'File::chmod' => 0,
        'File::Copy' => 0,
        'File::Find::Rule' => 0,
        'File::Path' => 0,
        'File::Temp' => 0,
        'Getopt::Long' => 0,
        'Time::localtime' => 0,
    },
    add_to_cleanup      => [ 'Phenyx-Utils-*' ],
);

$builder->create_build_script();
