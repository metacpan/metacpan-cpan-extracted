use strict;
use warnings FATAL => 'all';
use Module::Build;

my $build = Module::Build->new(
    license              => 'perl',
    create_license       => 1,
    recursive_test_files => 1,
    dynamic_config       => 0,
    build_requires       => {},
    configure_requires   => { 'Module::Build' => '0.38' },
    requires             => {
        'perl'       => 'v5.8.1',
        'Any::Moose' => '0.12',
        'IPC::Open3' => '1.02'
    },
    no_index    => { 'directory' => [ 'inc', 't', 'xt' ] },
    name        => 'Proc-Class',
    module_name => 'Proc::Class',
    abstract      => 'OO interface for process management',
    create_readme => 1,
    test_files    => -d '.git' ? 't/ xt/' : 't/',
);
$build->create_build_script();
