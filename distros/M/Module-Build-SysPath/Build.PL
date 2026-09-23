use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
    module_name        => 'Module::Build::SysPath',
    license            => 'perl',
    dist_author        => 'Jozef Kutej <jkutej@cpan.org>',
    dist_version_from  => 'lib/Module/Build/SysPath.pm',
    configure_requires => {'Module::Build' => '0.38',},
    requires           => {
        'Sys::Path'       => 0.17,
        'List::MoreUtils' => 0,
        'Digest::MD5'     => 0,
        'Text::Diff'      => 0,
        'File::Spec'      => 0,
        'File::Temp'      => 0,
        'Path::Tiny'      => 0.101,
    },
    build_requires => {
        'Capture::Tiny'         => 0,
        'Test::More'            => 0,
        'Test::Compile'         => 0.08,
        'Test::Dirs'            => 0,
        'File::Copy::Recursive' => 0,
        'File::Find::Rule'      => 0,
        'Monkey::Patch::Action' => 0,
    },
    add_to_cleanup => ['Module-Build-SysPath-*'],
    create_readme  => 1,
    meta_merge     => {
        'meta-spec' => {version => 2},
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/jozef/Module-Build-SysPath.git',
                web  => 'https://github.com/jozef/Module-Build-SysPath',
            },
            bugtracker => {web => 'https://github.com/jozef/Module-Build-SysPath/issues',},
        },
    },
);
$builder->create_build_script();
