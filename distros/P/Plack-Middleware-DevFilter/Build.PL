use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    name                => 'Plack-Middleware-DevFilter',
    module_name         => 'Plack::Middleware::DevFilter',
    license             => 'perl',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/Plack/Middleware/DevFilter.pm',
    configure_requires  => {
        'Module::Build' => 0.38,
    },
    build_requires      => {
        'Test::More' => 0.88,
    },
    requires => {
        'perl' => '5.008001',
        'Carp' => 0,
        'Plack::Middleware' => 0,
        'Plack::Util::Accessor' => 0,
        'Plack::Util' => 0,
        'Imager' => 0,
    },
    add_to_cleanup      => [ 'Plack-Middleware-DevFilter-*' ],
    meta_merge     => {
      resources => {
        repository  => 'http://github.com/bayashi/Plack-Middleware-DevFilter',
        bugtracker  => 'http://github.com/bayashi/Plack-Middleware-DevFilter/issues',
      }
    },
    recursive_test_files => 1,
    test_files => (-d '.git' || $ENV{RELEASE_TESTING}) ? ['t/', 'xt/'] : ['t/'],
);

$builder->create_build_script();
