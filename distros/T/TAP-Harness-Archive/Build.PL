use strict;
use warnings;
use Module::Build;
use lib './t/lib';

my $builder = Module::Build->new(
    module_name       => 'TAP::Harness::Archive',
    license           => 'perl',
    dist_author       => 'Michael Peters <mpeters@plusthree.com>',
    dist_version_from => 'lib/TAP/Harness/Archive.pm',
    requires          => {
        'TAP::Harness'     => 3.05,
        'Archive::Tar'     => 0,
        'Test::More'       => 0,
        'Cwd'              => 0,
        'File::Basename'   => 0,
        'File::Temp'       => 0.19,
        'File::Spec'       => 0,
        'File::Path'       => 0,
        'File::Find'       => 0,
        'YAML::Tiny'       => 0,
        'base'             => 2.18,
    },
    create_readme      => 1,
);

$builder->create_build_script()
