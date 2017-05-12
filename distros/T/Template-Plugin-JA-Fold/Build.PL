use strict;
use warnings FATAL => 'all';
use Module::Build;

Module::Build->new(
    name                 => 'Template-Plugin-JA-Fold',
    module_name          => 'Template::Plugin::JA::Fold',
    dist_author          => 'Hideaki Ohno<hide.o.j55@gmail.com>',
    license              => 'perl',
    recursive_test_files => 1,
    dynamic_config       => 0,
    build_requires       => {
        'Test::More'     => '0.98',
        'Template::Test' => 0,
    },
    configure_requires => { 'Module::Build' => '0.38' },
    requires           => {
        'perl'             => '5.008001',
        'Template'         => '2.00',
        'Lingua::JA::Fold' => '0.08',
    },
    no_index => { 'directory' => [ 't', 'xt', 'inc', 'eg' ] },
    test_files => ( -d '.git' || $ENV{RELEASE_TESTING} ) ? [qw(t/ xt/)] : ['t/'],
    create_readme  => 1,
    add_to_cleanup => ['Template-Plugin-JA-Fold-*'],
    meta_merge     => {
        keywords  => [qw/template fold/],
        resources => {
            repository => 'git://github.com/hideo55/p5-Template-Plugin-JA-Fold.git',
            bugtracker => 'https://github.com/hideo55/p5-Template-Plugin-JA-Fold/issues',
        },
    },
)->create_build_script;
