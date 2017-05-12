use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    name                => 'Plack-Middleware-Favicon',
    module_name         => 'Plack::Middleware::Favicon',
    license             => 'perl',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/Plack/Middleware/Favicon.pm',
    configure_requires  => {
        'Module::Build' => 0.38,
    },
    build_requires      => {
        'Test::More' => 0.88,
        'Plack::Test' => 0,
        'HTTP::Request::Common' => 0,
    },
    requires => {
        'perl' => '5.008001',
        'Carp' => 0,
        'parent' => 0,
        'Plack::Middleware' => 0,
        'Imager' => 0,
        'HTTP::Date' => 0,
        'Plack::Util::Accessor' => 0,
    },
    add_to_cleanup      => [ 'Plack-Middleware-Favicon-*' ],
    meta_merge     => {
      resources => {
        repository  => 'http://github.com/bayashi/Plack-Middleware-Favicon',
        bugtracker  => 'http://github.com/bayashi/Plack-Middleware-Favicon/issues',
      }
    },
    recursive_test_files => 1,
    test_files => (-d '.git' || $ENV{RELEASE_TESTING}) ? ['t/', 'xt/'] : ['t/'],
);

$builder->create_build_script();
