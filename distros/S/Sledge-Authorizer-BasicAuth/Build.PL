use strict;
use warnings FATAL => 'all';
use Module::Build;

my $build = Module::Build->new(
    license              => 'perl',
    recursive_test_files => 1,
    dynamic_config       => 0,
    build_requires       => { 'Test::More' => '0.98', 'Test::Exception' => 0, },
    configure_requires   => { 'Module::Build' => '0.38' },
    requires             => {
        perl                       => '5.008001',
        'Class::Data::Inheritable' => '0.08'
    },
    no_index    => { 'directory' => [ 't', 'inc' ] },
    name        => 'Sledge-Authorizer-BasicAuth',
    module_name => 'Sledge::Authorizer::BasicAuth',

    test_files => ( -d '.git' || $ENV{RELEASE_TESTING} ) ? 't/ xt/' : 't/',

    create_readme  => 1,
    create_license => 1,
);
$build->create_build_script();
