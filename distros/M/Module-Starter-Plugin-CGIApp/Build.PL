use strict;
use warnings;
use File::Find;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Module::Starter::Plugin::CGIApp',
    license             => 'perl',
    dist_author         => 'Jaldhar H. Vyas <jaldhar@braincells.com>',
    dist_version        => '0.44',
    share_dir           => 'share',
    pm_files            => {
        'lib/Module/Starter/Plugin/CGIApp.pm' => 'lib/Module/Starter/Plugin/CGIApp.pm',
    },
    script_files            => {
        'script/cgiapp-starter' => [],
        'script/titanium-starter' => [],
    },
    build_requires      => {
        'File::Copy::Recursive' => 0,
        'File::DirCompare'      => 0,
        'Test::More'            => 0,
        'Test::MockTime'        => 0,
        'Time::Piece'           => 1.12,
    },
    requires            => {
        'perl'                  => 5.008,
        'File::ShareDir'        => 0,
        'Module::Starter'       => 1.70,
        'HTML::Template'        => 0,
    },
    meta_merge => {
        resources => {
            repository  => 'http://github.com/jaldhar/Module-Starter-Plugin-CGIApp',
            homepage    => 'http://jaldhar.github.com/Module-Starter-Plugin-CGIApp/',
        },
    },
    add_to_cleanup      => [ 'Module-Starter-Plugin-CGIApp-*' ],
    create_makefile_pl  => 'small',
    sign                => 1,
);

$builder->create_build_script();

