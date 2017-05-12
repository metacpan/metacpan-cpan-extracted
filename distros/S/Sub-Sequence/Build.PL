use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Sub::Sequence',
    license             => 'perl',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/Sub/Sequence.pm',
    build_requires      => {
        'Test::More' => 0.88,
        'Test::Exception' => 0,
    },
    requires => {
        'perl' => '5.8.1',
        'Carp' => 0,
        'parent' => 0,
        'Exporter' => 0,
    },
    add_to_cleanup      => [ 'Sub-Sequence-*' ],
    meta_merge     => {
      resources => {
        repository  => 'http://github.com/bayashi/Sub-Sequence'
      }
    },
    recursive_test_files => 1,
);

$builder->create_build_script();
