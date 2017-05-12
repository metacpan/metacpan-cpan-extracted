use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    name                => 'Sub-Way',
    module_name         => 'Sub::Way',
    license             => 'perl',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/Sub/Way.pm',
    configure_requires  => {
        'Module::Build' => 0.38,
    },
    build_requires      => {
        'Test::More' => 0.88,
    },
    requires => {
        'perl' => '5.008001',
        'parent' => 0,
        'Exporter' => 0,
    },
    add_to_cleanup      => [ 'Sub-Way-*' ],
    meta_merge     => {
      resources => {
        repository  => 'http://github.com/bayashi/Sub-Way',
        bugtracker  => 'http://github.com/bayashi/Sub-Way/issues',
      }
    },
    recursive_test_files => 1,
    test_files => (-d '.git' || $ENV{RELEASE_TESTING}) ? ['t/', 'xt/'] : ['t/'],
);

$builder->create_build_script();
