#!perl
use strict;
use warnings;
use Module::Build;
use Module::Build::Compat;

my $builder = Module::Build->new(
    module_name    => 'Sys::Cmd',
    create_license => 1,
    create_readme  => 1,
    license        => 'GPL_3',
    dist_author    => 'Mark Lawrence <nomad@null.net>',
    dist_version   => '0.85.4',
    requires       => {
        'Carp'            => 0,
        'Exporter::Tidy'  => 0,
        'File::Which'     => 0,
        'File::chdir'     => 0,
        'IO::Handle'      => 0,
        'Log::Any'        => 0,
        'Proc::FastSpawn' => 0,
    },
    test_requires => {
        'Cwd'          => 0,
        'Data::Dumper' => 0,
        'File::Temp'   => 0,
        'File::Spec'   => 0,
        'Test::More'   => 0,
    },
    configure_requires => {
        'Module::Build' => '0.4004',
    },
    recursive_test_files => 1,
    add_to_cleanup       => ['Sys-Cmd-*'],
    create_makefile_pl   => 'small',
    meta_merge           => {
        resources => {
            bugtracker => 'https://github.com/mlawren/p5-Sys-Cmd/issues',
            repository => 'git://github.com/mlawren/p5-Sys-Cmd.git',
            homepage   => 'https://github.com/mlawren/p5-Sys-Cmd',
        },
        keywords => [],
    },
);

$builder->create_build_script();

# I prefer to use make when developing so lets built the Makefile here
# as well
Module::Build::Compat->write_makefile( build_class => 'Module::Build' );
