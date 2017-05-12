use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Module::Build::Smolder',
    license           => 'perl',
    dist_author       => 'Michael Peters <mpeters@plusthree.com>',
    dist_version_from => 'lib/Module/Build/Smolder.pm',
    requires          => {
        'TAP::Harness::Archive'     => 0.13,
        'Module::Build'             => 0.32,
        'Module::Build::TAPArchive' => 0,
        'WWW::Mechanize'            => 0,
    },
    build_requires => {
        'Test::More'    => 0,
        'Capture::Tiny' => 0,
        'File::Path'    => 0,
    },
    add_to_cleanup     => ['Module-Build-Smolder-*'],
);

$builder->create_build_script();
