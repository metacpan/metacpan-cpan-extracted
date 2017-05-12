use strict;
use Module::Build;

my $build = Module::Build->new(
    module_name  => 'Pod::Extract::URI',
    license      => 'perl',
    script_files => [],
    requires     => {
        'Pod::Parser'           => 0,
        'Pod::Escapes'          => 0,
        'URI::Find'             => 0,
        'URI::Find::Schemeless' => 0,
        'Carp'                  => 0,
    },
    build_requires => {
        'Test::More'    => '0',
        'Module::Build' => '0',
    },
    create_makefile_pl => 'passthrough',
);

$build->create_build_script;
