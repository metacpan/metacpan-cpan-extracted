use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Module::Mask::Deps',
    license             => 'perl',
    dist_author         => 'Matt Lawrence <mattlaw@cpan.org>',
    add_to_cleanup      => [ 'Module-Mask-Deps-*' ],
    create_makefile_pl  => 'small',

    requires => {
        'perl' => '5.8.0',
        'Module::Mask' => 0,
        'Module::CoreList' => '1.01',
    },
    build_requires => {
        'Test::More' => 0,
        # 'File::Find::Rule' => 0,
    },
    recommends => {
        'Test::Pod' => '1.14',
        'Test::Pod::Coverage' => '1.04',
    },
);

$builder->create_build_script;
