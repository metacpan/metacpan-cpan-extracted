use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Plack::Middleware::Debug::TraceENV',
    license             => 'perl',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/Plack/Middleware/Debug/TraceENV.pm',
    configure_requires  => {
        'Module::Build' => 0.42,
    },
    build_requires      => {
        'Test::More' => 0.88,
        'Plack::Test' => 0,
        'Plack::Builder' => 0,
        'HTTP::Request::Common' => 0,
    },
    requires => {
        'perl' => '5.8.1',
        'Plack::Middleware::Debug' => 0,
        'parent' => 0,
        'Plack::Util::Accessor' => 0,
    },
    add_to_cleanup      => [ 'Plack-Middleware-Debug-TraceENV-*' ],
    meta_merge     => {
      resources => {
        repository  => 'http://github.com/bayashi/Plack-Middleware-Debug-TraceENV'
      }
    },
);

$builder->create_build_script();
