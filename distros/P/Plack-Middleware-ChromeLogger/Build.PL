use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    name                => 'Plack-Middleware-ChromeLogger',
    module_name         => 'Plack::Middleware::ChromeLogger',
    license             => 'perl',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/Plack/Middleware/ChromeLogger.pm',
    configure_requires  => {
        'Module::Build' => 0.38,
    },
    build_requires      => {
        'Test::More' => 0.88,
        'Plack::Builder' => 0,
        'HTTP::Request::Common' => 0,
        'LWP::UserAgent' => 0,
        'Plack::Test' => 0,
        'MIME::Base64' => 0,
        'JSON' => 0,
    },
    requires => {
        'perl' => '5.008001',
        'Web::ChromeLogger' => 0.04,
        'Plack::Middleware' => 0,
        'Plack::Util' => 0,
        'Plack::Util::Accessor' => 0,
    },
    add_to_cleanup      => [ 'Plack-Middleware-ChromeLogger-*' ],
    meta_merge     => {
      resources => {
        repository  => 'http://github.com/bayashi/Plack-Middleware-ChromeLogger',
        bugtracker  => 'http://github.com/bayashi/Plack-Middleware-ChromeLogger/issues',
      }
    },
    recursive_test_files => 1,
    test_files => (-d '.git' || $ENV{RELEASE_TESTING}) ? ['t/', 'xt/'] : ['t/'],
);

$builder->create_build_script();
