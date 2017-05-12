use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Module::Build::SysPath',
    license             => 'perl',
    dist_author         => 'Jozef Kutej <jkutej@cpan.org>',
    dist_version_from   => 'lib/Module/Build/SysPath.pm',
    configure_requires => {
        'Module::Build' => '0.3607',
    },
    requires => {
        'Sys::Path'       => 0.11,
        'List::MoreUtils' => 0,
        'Digest::MD5'     => 0,
        'Text::Diff'      => 0,
        'File::Spec'      => 0,
        'File::Basename'  => 0,
        'File::Path'      => 2.07,    # Introduce make_path() and rm_tree() API extension.
    },
    build_requires => {
        'Test::More'    => 0,
        'Test::Compile' => 0.08,
        'Test::Dirs'    => 0,
        'File::Temp'    => 0,
        'File::Find::Rule' => 0,
    },
    add_to_cleanup      => [ 'Module-Build-SysPath-*' ],
    create_readme       => 1,
    meta_merge => {
        resources => {
            repository => 'git://github.com/jozef/Module-Build-SysPath.git',
            bugtracker => 'http://github.com/jozef/Module-Build-SysPath/issues',
        },
        keywords => [ qw/ system paths instalation deployment applications / ],
    },
);
$builder->create_build_script();
