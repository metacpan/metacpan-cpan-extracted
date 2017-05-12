use strict;
use warnings;
use Module::Build::Pluggable qw/CPANfile/;

my $builder = Module::Build::Pluggable->new(
    name                => 'Sub-Mux',
    module_name         => 'Sub::Mux',
    license             => 'perl',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/Sub/Mux.pm',
    add_to_cleanup      => [ 'Sub-Mux-*' ],
    meta_merge     => {
      resources => {
        repository  => 'http://github.com/bayashi/Sub-Mux',
        bugtracker  => 'http://github.com/bayashi/Sub-Mux/issues',
      }
    },
    test_files => (-d '.git' || $ENV{RELEASE_TESTING}) ? ['t/', 'xt/'] : ['t/'],
    recursive_test_files => 1,
    create_license => 1,
);

$builder->create_build_script();
