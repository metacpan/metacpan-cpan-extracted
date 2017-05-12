use strict;
use warnings;
use Module::Build;

die 'OS unsupported! Patches welcome :)' unless $^O =~ /linux/i;

my $builder = Module::Build->new(
    module_name        => 'Sys::Prctl',
    license            => 'perl',
    dist_author        => 'Troels Liebe Bentsen <troels@infopro.dk>',
    dist_version_from  => 'lib/Sys/Prctl.pm',
    create_makefile_pl => 'passthrough',
    create_readme      => 1,
    requires => {
        'POSIX'  => 0,
        'Config' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup => [ 
        'Sys-Prctl-*',
        'Makefile',
        'blib',
    ],
);

$builder->create_build_script();
