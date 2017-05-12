use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Module::Build::TAPArchive',
    license           => 'perl',
    dist_author       => 'Michael Peters <mpeters@plusthree.com>',
    dist_version_from => 'lib/Module/Build/TAPArchive.pm',
    requires          => {
        'Module::Build'         => 0.32,
        'TAP::Harness::Archive' => 0.13,
    },
    build_requires => {
        'Capture::Tiny' => 0.06,
        'Test::More'    => 0,
        'File::Path'    => 0,
    },
    add_to_cleanup     => ['Module-Build-TAPArchive-*'],
);

$builder->create_build_script();
