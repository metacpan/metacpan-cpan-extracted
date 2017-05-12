use strict;
use warnings FATAL => 'all';
use Module::Build;

my $build = Module::Build->new(
    license              => 'perl',
    recursive_test_files => 1,
    dynamic_config       => 0,
    build_requires       => { 'Test::More' => '0.98' },
    configure_requires   => { 'Module::Build' => '0.38' },
    requires             => {
        perl             => '5.008001',
        'Test::More'     => '0.32',
        'Data::Dumper'   => '2.121',
        'Sledge::Pages::Base' => '0',
        'Jcode'          => '0.88',
        'Template'       => '2.14'
    },
    no_index    => { 'directory' => [ 't', 'inc' ] },
    name        => 'Sledge-Plugin-DebugMessage',
    module_name => 'Sledge::Plugin::DebugMessage',

    test_files => ( -d '.git' || $ENV{RELEASE_TESTING} ) ? 't/ xt/' : 't/',

    create_readme  => 1,
    create_license => 1,
);
$build->create_build_script();
