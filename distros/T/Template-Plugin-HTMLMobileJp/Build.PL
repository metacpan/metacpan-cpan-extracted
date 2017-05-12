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
        'Filter::Util::Call' => '0',
        'Template'           => '0',
        'HTML::MobileJp'     => '0'
    },
    no_index    => { 'directory' => [ 'inc', 't' ] },
    name        => 'Template-Plugin-HTMLMobileJp',
    module_name => 'Template::Plugin::HTMLMobileJp',

    test_files => ( -d '.git' || $ENV{RELEASE_TESTING} ) ? 't/ xt/' : 't/',

    create_readme  => 1,
    create_license => 1,
);
$build->create_build_script();
