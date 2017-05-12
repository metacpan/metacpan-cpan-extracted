use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Plack::Middleware::TimeStats',
    license             => 'perl',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/Plack/Middleware/TimeStats.pm',
    configure_requires  => {
        'Module::Build' => 0.38,
    },
    build_requires      => {
        'Test::More' => 0.88,
        'Capture::Tiny' => 0,
        'Plack::Builder' => 0,
        'HTTP::Request::Common' => 0,
        'Plack::Test' => 0,
    },
    requires => {
        'perl' => '5.008001',
        'Plack::Middleware' => 0,
        'Plack::Util::Accessor' => 0,
        'Devel::TimeStats' => 0.03,
    },
    add_to_cleanup      => [ 'Plack-Middleware-TimeStats-*' ],
    meta_merge     => {
      resources => {
        repository  => 'http://github.com/bayashi/Plack-Middleware-TimeStats'
      }
    },
    recursive_test_files => 1,
);

$builder->create_build_script();
