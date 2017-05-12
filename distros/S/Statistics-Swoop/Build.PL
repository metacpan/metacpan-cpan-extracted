use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Statistics::Swoop',
    license             => 'perl',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/Statistics/Swoop.pm',
    configure_requires  => {
        'Module::Build' => 0.38,
    },
    build_requires      => {
        'Test::More' => 0.88,
    },
    requires => {
        'perl' => '5.008001',
        'Carp' => 0,
        'Class::Accessor::Lite' => 0,
    },
    recommends => {
        'Getopt::Long' => '2.42',
        'Pod::Usage' => 0,
        'Text::ASCIITable' => 0,
    },
    script_files        => [ 'script/swoop' ],
    add_to_cleanup      => [ 'Statistics-Swoop-*' ],
    meta_merge     => {
      resources => {
        repository  => 'http://github.com/bayashi/Statistics-Swoop'
      }
    },
    recursive_test_files => 1,
);

$builder->create_build_script();
