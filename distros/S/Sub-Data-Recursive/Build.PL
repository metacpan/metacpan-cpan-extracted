use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Sub::Data::Recursive',
    license             => 'perl',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/Sub/Data/Recursive.pm',
    configure_requires  => {
        'Module::Build' => 0.38,
    },
    build_requires      => {
        'Test::More' => 0.88,
        'Encode' => 0,
    },
    requires => {
        'perl' => '5.008001',
        'Scalar::Util' => 0,
    },
    add_to_cleanup      => [ 'Sub-Data-Recursive-*' ],
    meta_merge     => {
      resources => {
        repository  => 'http://github.com/bayashi/Sub-Data-Recursive'
      }
    },
    recursive_test_files => 1,
);

$builder->create_build_script();
