use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    name                => 'Plack-Middleware-EnvTracer',
    module_name         => 'Plack::Middleware::EnvTracer',
    license             => 'perl',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/Plack/Middleware/EnvTracer.pm',
    configure_requires  => {
        'Module::Build' => 0.4218,
    },
    build_requires      => {
        'Test::More' => 0.88,
        'Plack::Test' => 0,
        'Plack::Builder' => 0,
        'HTTP::Request::Common' => 0,
        'Capture::Tiny' => 0,
    },
    requires => {
        'perl' => '5.008008',
        'parent' => 0,
        'Plack::Middleware' => 0,
        'Plack::Util::Accessor' => 0,
    },
    add_to_cleanup      => [ 'Plack-Middleware-EnvTracer-*' ],
    meta_merge     => {
      resources => {
        repository  => 'http://github.com/bayashi/Plack-Middleware-EnvTracer',
        bugtracker  => 'http://github.com/bayashi/Plack-Middleware-EnvTracer/issues',
      }
    },
    recursive_test_files => 1,
    test_files => (-d '.git' || $ENV{RELEASE_TESTING}) ? ['t/', 'xt/'] : ['t/'],
);

$builder->create_build_script();
